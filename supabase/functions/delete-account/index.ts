import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(
  payload: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // Extract the user's access token from the Authorization header
  const authHeader = req.headers.get("authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return jsonResponse({ error: "Missing or invalid authorization header" }, 401);
  }
  const accessToken = authHeader.replace("Bearer ", "");

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  // Create a client with the user's token to verify identity
  const userClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  });

  // Verify the user's token and get their identity
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser(accessToken);

  if (userError || !user) {
    console.error("delete-account: auth verification failed", userError);
    return jsonResponse({ error: "Invalid or expired token" }, 401);
  }

  const userId = user.id;
  const userEmail = user.email;
  console.log(`delete-account: deleting user ${userEmail} (${userId})`);

  // Create admin client for privileged operations
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Step 1: Delete the user's profile row.
  // organization_sessions, purchases and user_settings reference profiles.id
  // with ON DELETE CASCADE, so those rows are removed automatically here.
  const { error: profileError } = await adminClient
    .from("profiles")
    .delete()
    .eq("id", userId);

  if (profileError) {
    console.error("delete-account: profile deletion failed", profileError);
    // Continue anyway - the auth user deletion is more important
  } else {
    console.log(`delete-account: profile deleted for ${userEmail}`);
  }

  // Step 2: Delete remaining personal data that is NOT covered by the profiles cascade.
  // These deletes are scoped to this user only, so they are safe no-ops if a row is absent.
  // Failures are logged but never block account deletion.
  if (userEmail) {
    const { error: appleTxError } = await adminClient
      .from("apple_transactions")
      .delete()
      .eq("user_email", userEmail);
    if (appleTxError) {
      console.error("delete-account: apple_transactions cleanup failed", appleTxError);
    }

    const { error: promoError } = await adminClient
      .from("promo_code_redemptions")
      .delete()
      .eq("user_email", userEmail);
    if (promoError) {
      console.error("delete-account: promo redemption cleanup failed", promoError);
    }
  }

  // Note: user_analytics is a VIEW derived from profiles-backed tables, so it is emptied
  // automatically by the profile cascade above — no explicit delete is possible or needed.

  // Step 3: Delete the auth user. This is the authoritative step — once this succeeds
  // the account can never be signed into again.
  const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);

  if (deleteError) {
    console.error("delete-account: auth user deletion failed", deleteError);
    return jsonResponse(
      { error: "Failed to delete account. Please try again or contact support." },
      500,
    );
  }

  console.log(`delete-account: user ${userEmail} fully deleted`);

  return jsonResponse({
    success: true,
    message: "Account deleted successfully",
  });
});
