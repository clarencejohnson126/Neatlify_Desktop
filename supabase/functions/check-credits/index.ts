import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

type CreditAction = "check" | "deduct" | "balance";

type CheckCreditsRequest = {
  user_email?: unknown;
  file_count?: unknown;
  action?: unknown;
};

type ProfileCreditsRow = {
  credits_total: number | null;
  credits_used: number | null;
  credits_remaining: number | null;
};

const FUNCTION_VERSION = "v15";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(payload: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify({ version: FUNCTION_VERSION, ...payload }), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function parseEmail(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim().toLowerCase();
  if (!trimmed) return null;
  return trimmed;
}

function parseNonNegativeInt(value: unknown): number | null {
  if (value === undefined || value === null) return null;

  if (typeof value === "number" && Number.isFinite(value)) {
    if (!Number.isInteger(value)) return null;
    return value >= 0 ? value : null;
  }

  if (typeof value === "string") {
    const trimmed = value.trim();
    if (!/^\d+$/.test(trimmed)) return null;
    const parsed = Number.parseInt(trimmed, 10);
    return Number.isSafeInteger(parsed) && parsed >= 0 ? parsed : null;
  }

  return null;
}

function normalizeCredits(row: ProfileCreditsRow): {
  creditsTotal: number;
  creditsUsed: number;
  creditsRemaining: number;
} {
  const creditsTotal = Number.isFinite(row.credits_total)
    ? Math.trunc(row.credits_total ?? 0)
    : 0;
  const creditsUsed = Number.isFinite(row.credits_used)
    ? Math.trunc(row.credits_used ?? 0)
    : 0;

  const creditsRemainingFromDb = row.credits_remaining;
  const creditsRemaining = Number.isFinite(creditsRemainingFromDb)
    ? Math.trunc(creditsRemainingFromDb ?? 0)
    : creditsTotal - creditsUsed;

  return { creditsTotal, creditsUsed, creditsRemaining };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let body: CheckCreditsRequest;
  try {
    body = (await req.json()) as CheckCreditsRequest;
  } catch {
    return jsonResponse({ allowed: false, error: "Invalid JSON body" }, 400);
  }

  const userEmail = parseEmail(body.user_email);
  if (!userEmail) {
    return jsonResponse(
      { allowed: false, error: "Missing or invalid user_email" },
      400,
    );
  }

  const rawAction = typeof body.action === "string" ? body.action : "check";
  const action = rawAction as CreditAction;
  if (action !== "check" && action !== "deduct" && action !== "balance") {
    return jsonResponse({ error: "Invalid action" }, 400);
  }

  const fileCountParsed = parseNonNegativeInt(body.file_count);
  const fileCount = fileCountParsed ?? 0;

  if ((action === "check" || action === "deduct") && fileCountParsed === null) {
    return jsonResponse({ allowed: false, error: "Invalid file_count" }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(
      { allowed: false, error: "Server configuration error" },
      500,
    );
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const loadProfileCredits = async (): Promise<
    { row: ProfileCreditsRow; error: unknown } | { row: null; error: unknown }
  > => {
    const { data, error } = await supabase
      .from("profiles")
      .select("credits_total,credits_used,credits_remaining")
      .eq("email", userEmail)
      .maybeSingle();
    return { row: (data as ProfileCreditsRow | null) ?? null, error };
  };

  const loaded = await loadProfileCredits();
  if (loaded.error) {
    console.error("check-credits: profile lookup error", loaded.error);
    return jsonResponse(
      { allowed: false, error: "Failed to load user profile" },
      500,
    );
  }

  if (!loaded.row) {
    return jsonResponse({
      allowed: false,
      error: "User profile not found",
      credits_available: 0,
    });
  }

  let { creditsUsed, creditsRemaining } = normalizeCredits(loaded.row);
  let creditsUsedIsNull = loaded.row.credits_used === null;

  if (action === "balance") {
    return jsonResponse({
      allowed: true,
      credits_available: creditsRemaining,
      credits_after: creditsRemaining,
    });
  }

  if (action === "check") {
    if (creditsRemaining >= fileCount) {
      return jsonResponse({
        allowed: true,
        credits_available: creditsRemaining,
        credits_after: creditsRemaining - fileCount,
      });
    }

    return jsonResponse({
      allowed: false,
      error: `Need ${fileCount}, have ${creditsRemaining}`,
      credits_available: creditsRemaining,
      credits_needed: fileCount,
    });
  }

  // action === "deduct"
  if (fileCount === 0) {
    return jsonResponse({
      allowed: true,
      credits_deducted: 0,
      credits_remaining: creditsRemaining,
    });
  }

  if (creditsRemaining < fileCount) {
    return jsonResponse({
      allowed: false,
      error: `Need ${fileCount}, have ${creditsRemaining}`,
      credits_available: creditsRemaining,
      credits_needed: fileCount,
    });
  }

  // Optimistic concurrency: only update if credits_used hasn't changed.
  for (let attempt = 0; attempt < 3; attempt++) {
    const updateTo = creditsUsed + fileCount;

    let update = supabase
      .from("profiles")
      .update({ credits_used: updateTo })
      .eq("email", userEmail)
      .gte("credits_remaining", fileCount);

    update =
      creditsUsedIsNull ? update.is("credits_used", null) : update.eq("credits_used", creditsUsed);

    const { data: updated, error: updateError } = await update
      .select("credits_total,credits_used,credits_remaining")
      .maybeSingle();

    if (updateError) {
      console.error("check-credits: update error", updateError);
      return jsonResponse(
        { allowed: false, error: `Update failed: ${updateError.message}` },
        500,
      );
    }

    if (updated) {
      const normalized = normalizeCredits(updated as ProfileCreditsRow);
      return jsonResponse({
        allowed: true,
        credits_deducted: fileCount,
        credits_remaining: normalized.creditsRemaining,
      });
    }

    // Row wasn't updated (concurrent update or insufficient credits). Reload and retry.
    const refreshed = await loadProfileCredits();
    if (refreshed.error) {
      console.error("check-credits: refresh error", refreshed.error);
      return jsonResponse(
        { allowed: false, error: "Failed to refresh user profile" },
        500,
      );
    }

    if (!refreshed.row) {
      return jsonResponse({
        allowed: false,
        error: "User profile not found",
        credits_available: 0,
      });
    }

    const normalized = normalizeCredits(refreshed.row);
    creditsUsed = normalized.creditsUsed;
    creditsRemaining = normalized.creditsRemaining;
    creditsUsedIsNull = refreshed.row.credits_used === null;

    if (creditsRemaining < fileCount) {
      return jsonResponse({
        allowed: false,
        error: `Need ${fileCount}, have ${creditsRemaining}`,
        credits_available: creditsRemaining,
        credits_needed: fileCount,
      });
    }
  }

  return jsonResponse(
    {
      allowed: false,
      error: "Concurrent update detected. Please retry.",
    },
    409,
  );
});
