import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status, headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
function key(single: string[], map: string): string | null {
  for (const name of single) {
    const value = Deno.env.get(name);
    if (value) return value;
  }
  try {
    const parsed = JSON.parse(Deno.env.get(map) ?? "{}");
    return typeof parsed.default === "string" ? parsed.default : null;
  } catch { return null; }
}
async function context(req: Request) {
  const url = Deno.env.get("SUPABASE_URL");
  const publishable = key(["SUPABASE_PUBLISHABLE_KEY", "SUPABASE_ANON_KEY"], "SUPABASE_PUBLISHABLE_KEYS");
  const secret = key(["SUPABASE_SECRET_KEY", "SUPABASE_SERVICE_ROLE_KEY"], "SUPABASE_SECRET_KEYS");
  const auth = req.headers.get("Authorization") ?? "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (!url || !publishable || !secret) throw new Error("SUPABASE_SERVER_CONFIGURATION_MISSING");
  if (!token || token === auth) throw new Error("UNAUTHENTICATED");

  const userClient = createClient(url, publishable, {
    global: { headers: { Authorization: "Bearer " + token } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await userClient.auth.getUser(token);
  if (error || !data.user) throw new Error("UNAUTHENTICATED");

  const admin = createClient(url, secret, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return { admin, user: data.user };
}
function median(values: number[]): number {
  const sorted = [...values].sort((a, b) => a - b);
  if (!sorted.length) return 0;
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);

  let ctx: Awaited<ReturnType<typeof context>>;
  try { ctx = await context(req); }
  catch (error) {
    const message = error instanceof Error ? error.message : "UNAUTHENTICATED";
    return json({ error: message }, message === "UNAUTHENTICATED" ? 401 : 503);
  }

  try {
    const body = await req.json();
    const productId = typeof body.product_id === "string" ? body.product_id : "";
    if (!productId) return json({ error: "PRODUCT_ID_REQUIRED" }, 400);

    const { data: product, error: productError } = await ctx.admin
      .from("products")
      .select("id,artisan_profile_id,category_id,title,craft_origin,materials,techniques,currency")
      .eq("id", productId).maybeSingle();
    if (productError || !product) return json({ error: "PRODUCT_NOT_FOUND" }, 404);

    const { data: artisan } = await ctx.admin
      .from("artisan_profiles").select("id,user_id,state,craft_region")
      .eq("id", product.artisan_profile_id).maybeSingle();
    if (!artisan || artisan.user_id !== ctx.user.id) {
      return json({ error: "PRODUCT_NOT_OWNED_BY_USER" }, 403);
    }

    if (!product.category_id) {
      return json({
        status: "insufficient_data",
        product_id: productId,
        comparable_count: 0,
        price_range: null,
        message: "Assign a craft category before requesting market-price guidance.",
      });
    }

    const { data: observations, error: observationError } = await ctx.admin
      .from("market_price_observations")
      .select("id,price_min,price_max,currency,unit,source_name,source_url,observed_at,region,craft_terms")
      .eq("category_id", product.category_id)
      .eq("is_verified", true)
      .order("observed_at", { ascending: false })
      .limit(100);
    if (observationError) throw observationError;

    const cutoff = Date.now() - 365 * 24 * 60 * 60 * 1000;
    const productTerms = [
      ...(Array.isArray(product.materials) ? product.materials : []),
      ...(Array.isArray(product.techniques) ? product.techniques : []),
    ].map((term: unknown) => String(term).toLowerCase());
    const productRegion = String(artisan.craft_region || artisan.state || "").toLowerCase();

    const comparable = (observations ?? []).filter((row: Record<string, unknown>) => {
      const observedAt = Date.parse(String(row.observed_at));
      if (!Number.isFinite(observedAt) || observedAt < cutoff) return false;
      if (product.currency && row.currency !== product.currency) return false;

      const sourceRegion = String(row.region ?? "").toLowerCase();
      const observationTerms = Array.isArray(row.craft_terms)
        ? row.craft_terms.map((term: unknown) => String(term).toLowerCase())
        : [];

      const hasTermOverlap = productTerms.length === 0 ||
        productTerms.some((term) => observationTerms.some((sourceTerm) =>
          sourceTerm.includes(term) || term.includes(sourceTerm)
        ));
      const regionCompatible = !productRegion || !sourceRegion ||
        sourceRegion.includes(productRegion) || productRegion.includes(sourceRegion);

      return hasTermOverlap && regionCompatible;
    });

    if (comparable.length < 3) {
      const { data: saved } = await ctx.admin.from("product_price_guidance").insert({
        product_id: productId,
        artisan_user_id: ctx.user.id,
        indicative_min: null,
        indicative_max: null,
        currency: product.currency || "INR",
        comparable_count: comparable.length,
        confidence: "insufficient_data",
        explanation: "Fewer than three recent, verified comparable observations were available. No price was estimated.",
        source_observation_ids: comparable.map((row: Record<string, unknown>) => row.id),
      }).select("id").single();

      return json({
        status: "insufficient_data",
        guidance_id: saved?.id ?? null,
        product_id: productId,
        comparable_count: comparable.length,
        price_range: null,
        message: "There is not enough verified comparable market data to suggest a price. No value has been invented.",
      });
    }

    const lowValues = comparable.map((row: Record<string, unknown>) => Number(row.price_min)).filter(Number.isFinite);
    const highValues = comparable.map((row: Record<string, unknown>) => Number(row.price_max)).filter(Number.isFinite);
    const low = median(lowValues);
    const high = median(highValues);
    const count = comparable.length;
    const confidence = count >= 15 ? "high" : count >= 6 ? "medium" : "low";
    const sources = comparable.map((row: Record<string, unknown>) => ({
      source_name: row.source_name,
      source_url: row.source_url,
      observed_at: row.observed_at,
      region: row.region,
    }));

    const { data: saved, error: saveError } = await ctx.admin
      .from("product_price_guidance")
      .insert({
        product_id: productId,
        artisan_user_id: ctx.user.id,
        indicative_min: low,
        indicative_max: high,
        currency: product.currency || "INR",
        unit: comparable[0].unit || "piece",
        comparable_count: count,
        confidence,
        explanation: "Median of recent verified observation ranges in the same craft category, filtered by compatible terms and region where available. This is indicative guidance, not a guaranteed selling price or appraisal.",
        source_observation_ids: comparable.map((row: Record<string, unknown>) => row.id),
      })
      .select("id").single();
    if (saveError) throw saveError;

    return json({
      status: "ok",
      guidance_id: saved.id,
      product_id: productId,
      price_range: { min: low, max: high, currency: product.currency || "INR", unit: comparable[0].unit || "piece" },
      comparable_count: count,
      confidence,
      sources,
      disclaimer: "Indicative comparison only. The artisan chooses the final price. This guidance is not an appraisal or price guarantee.",
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "PRICE_GUIDANCE_FAILED";
    console.error("price-guidance:", message);
    return json({ error: "PRICE_GUIDANCE_FAILED", message }, 500);
  }
});
