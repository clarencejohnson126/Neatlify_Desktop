import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

interface VerifyAppleTransactionRequest {
  transaction_id: string;
  original_transaction_id: string;
  product_id: string;
  purchase_date: number; // milliseconds since epoch
  user_email: string;
}

// Credit mapping based on product ID
const PRODUCT_CREDITS: Record<string, number> = {
  "com.neatlify.Desktop.starter": 100,
  "com.neatlify.Desktop.pro": 1000,
  "com.neatlify.Desktop.business": 10000,
};

serve(async (req: Request) => {
  // Only POST requests
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ success: false, error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } }
    );
  }

  try {
    const body: VerifyAppleTransactionRequest = await req.json();

    // Validate required fields
    if (
      !body.transaction_id ||
      !body.original_transaction_id ||
      !body.product_id ||
      !body.user_email
    ) {
      return new Response(
        JSON.stringify({
          success: false,
          error:
            "Missing required fields: transaction_id, original_transaction_id, product_id, user_email",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Get credit amount for this product
    const creditsToGrant = PRODUCT_CREDITS[body.product_id];
    if (!creditsToGrant) {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Unknown product ID: ${body.product_id}`,
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Server configuration error",
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Check if transaction already processed (dedup by original_transaction_id)
    const { data: existingTransaction, error: lookupError } = await supabase
      .from("apple_transactions")
      .select("*")
      .eq("original_transaction_id", body.original_transaction_id)
      .single();

    if (lookupError && lookupError.code !== "PGRST116") {
      // PGRST116 = not found (expected for new transactions)
      throw lookupError;
    }

    if (existingTransaction) {
      // Already processed - return current balance without adding more credits
      const { data: profile, error: profileError } = await supabase
        .from("profiles")
        .select("file_credits")
        .eq("email", body.user_email)
        .single();

      if (profileError) {
        console.error("Failed to read profile balance:", profileError);
      }

      return new Response(
        JSON.stringify({
          success: true,
          credits_added: 0,
          // Only include credits_total when we actually read it. The client treats
          // a missing field as "trust the local balance" instead of overwriting to 0.
          ...(profile ? { credits_total: profile.file_credits } : {}),
          message: "Transaction already processed",
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // Add credits to user's account
    const { data: creditResult, error: creditError } = await supabase.rpc(
      "add_credits",
      {
        p_email: body.user_email,
        p_credits: creditsToGrant,
      }
    );

    if (creditError) {
      throw creditError;
    }

    // Record transaction in apple_transactions table
    const transactionDate = body.purchase_date
      ? new Date(body.purchase_date).toISOString()
      : new Date().toISOString();

    const { error: insertError } = await supabase
      .from("apple_transactions")
      .insert({
        original_transaction_id: body.original_transaction_id,
        product_id: body.product_id,
        user_email: body.user_email,
        credits_granted: creditsToGrant,
        transaction_date: transactionDate,
      });

    if (insertError) {
      // Log but don't fail - credits were already added
      console.error("Failed to record transaction:", insertError);
    }

    // Get updated balance. If the profile lookup misses for any reason
    // (replica lag, email-casing mismatch), omit credits_total entirely
    // instead of returning 0 — the credits were granted by add_credits and
    // we must not signal a zero balance to the client.
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("file_credits")
      .eq("email", body.user_email)
      .single();

    if (profileError) {
      console.error("Failed to read profile after add_credits:", profileError);
    }

    return new Response(
      JSON.stringify({
        success: true,
        credits_added: creditsToGrant,
        ...(profile ? { credits_total: profile.file_credits } : {}),
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error verifying Apple transaction:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
