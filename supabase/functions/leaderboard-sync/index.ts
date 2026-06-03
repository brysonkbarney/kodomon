import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

const RATE_LIMIT_SECONDS = 300;
const rateLimitMap = new Map<string, number>();
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const speciesPattern = /^[a-z0-9_-]{1,64}$/;
const allowedSorts = new Set([
  "total_xp",
  "lifetime_xp",
  "current_streak",
  "active_days",
  "total_commits",
  "lines_written",
]);
const allowedStages = new Set(["tamago", "kobito", "kani", "kamisama"]);

function corsHeaders(origin?: string | null) {
  return {
    "Access-Control-Allow-Origin": origin || "*",
    "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Kodomon-Id",
  };
}

function jsonResponse(payload: unknown, init: ResponseInit = {}, origin?: string | null) {
  return new Response(JSON.stringify(payload), {
    ...init,
    headers: {
      ...corsHeaders(origin),
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });
}

function readNumber(value: unknown, fallback: number) {
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function clampNumber(value: unknown, fallback: number, min: number, max: number) {
  return Math.max(min, Math.min(readNumber(value, fallback), max));
}

function clampInteger(value: unknown, fallback: number, min: number, max: number) {
  return Math.max(min, Math.min(Math.floor(readNumber(value, fallback)), max));
}

function cleanString(value: unknown, fallback: string, maxLength: number) {
  if (typeof value !== "string") return fallback;
  const trimmed = value.trim();
  return (trimmed || fallback).slice(0, maxLength);
}

function cleanStringArray(value: unknown, maxItems: number, maxLength: number) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim().slice(0, maxLength))
    .filter((item) => item.length > 0)
    .slice(0, maxItems);
}

function cleanSpeciesId(value: unknown) {
  if (typeof value !== "string") return "tamago_crab";
  const cleaned = value.trim().slice(0, 64);
  return speciesPattern.test(cleaned) ? cleaned : "tamago_crab";
}

function getKodomonId(req: Request) {
  const id = req.headers.get("X-Kodomon-Id")?.trim() || "";
  return uuidPattern.test(id) ? id : null;
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders(origin) });
  }

  try {
    if (req.method === "GET") {
      const url = new URL(req.url);
      const requestedSort = url.searchParams.get("sort") || "lifetime_xp";
      const sortCol = allowedSorts.has(requestedSort) ? requestedSort : "lifetime_xp";
      const limit = clampInteger(url.searchParams.get("limit"), 50, 1, 100);

      const { data, error } = await supabase
        .from("leaderboard")
        .select("id, pet_name, total_xp, lifetime_xp, stage, species_id, current_streak, longest_streak, active_days, total_commits, lines_written, mood, equipped_accessories, active_background, pet_hue, sprite_url, updated_at")
        .order(sortCol, { ascending: false })
        .order("updated_at", { ascending: false })
        .limit(limit);

      if (error) throw error;
      return jsonResponse(data ?? [], {}, origin);
    }

    const kodomonId = getKodomonId(req);
    if (!kodomonId) {
      return jsonResponse({ error: "Missing or invalid X-Kodomon-Id" }, { status: 401 }, origin);
    }

    if (req.method === "DELETE") {
      const { error } = await supabase
        .from("leaderboard")
        .delete()
        .eq("id", kodomonId);

      if (error) throw error;
      return jsonResponse({ ok: true }, {}, origin);
    }

    if (req.method === "POST") {
      const now = Date.now();
      const lastSync = rateLimitMap.get(kodomonId) || 0;
      if (now - lastSync < RATE_LIMIT_SECONDS * 1000) {
        const retryAfter = Math.ceil((RATE_LIMIT_SECONDS * 1000 - (now - lastSync)) / 1000);
        return jsonResponse(
          { error: "Rate limited", retry_after: retryAfter },
          { status: 429, headers: { "Retry-After": String(retryAfter) } },
          origin
        );
      }

      const body = await req.json();
      const stage = typeof body.stage === "string" && allowedStages.has(body.stage) ? body.stage : "tamago";
      const row = {
        id: kodomonId,
        pet_name: cleanString(body.pet_name, "Kodomon", 50),
        total_xp: clampNumber(body.total_xp, 0, 0, 200000),
        lifetime_xp: clampNumber(body.lifetime_xp ?? body.total_xp, 0, 0, 500000),
        stage,
        species_id: cleanSpeciesId(body.species_id),
        current_streak: clampInteger(body.current_streak, 0, 0, 365),
        longest_streak: clampInteger(body.longest_streak, 0, 0, 365),
        active_days: clampInteger(body.active_days, 0, 0, 3650),
        total_commits: clampInteger(body.total_commits, 0, 0, 100000),
        lines_written: clampInteger(body.lines_written, 0, 0, 10000000),
        mood: clampNumber(body.mood, 50, 0, 100),
        equipped_accessories: cleanStringArray(body.equipped_accessories, 10, 40),
        active_background: cleanString(body.active_background, "none", 30),
        pet_hue: clampNumber(body.pet_hue, 0, 0, 1),
        updated_at: new Date().toISOString(),
      };

      const { error } = await supabase
        .from("leaderboard")
        .upsert(row, { onConflict: "id" });

      if (error) throw error;

      rateLimitMap.set(kodomonId, now);
      return jsonResponse({ ok: true }, {}, origin);
    }

    return jsonResponse({ error: "Method not allowed" }, { status: 405 }, origin);
  } catch (err) {
    console.error(err);
    return jsonResponse({ error: "Internal server error" }, { status: 500 }, origin);
  }
});
