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
function tokens(value: string): Set<string> {
  return new Set(
    value.toLowerCase().split(/[^a-z0-9]+/).filter((word) => word.length > 2),
  );
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
      .select("id,artisan_profile_id,category_id,title,short_description,description,materials,techniques,price,currency,available_quantity,status")
      .eq("id", productId).maybeSingle();
    if (productError || !product) return json({ error: "PRODUCT_NOT_FOUND" }, 404);

    const { data: artisan } = await ctx.admin
      .from("artisan_profiles").select("id,user_id,state,craft_region")
      .eq("id", product.artisan_profile_id).maybeSingle();
    if (!artisan || artisan.user_id !== ctx.user.id) {
      return json({ error: "PRODUCT_NOT_OWNED_BY_USER" }, 403);
    }
    if (product.status !== "published") {
      return json({
        error: "PRODUCT_NOT_PUBLISHED",
        message: "Only published products can be matched with buyers.",
      }, 409);
    }

    const { data: requests, error: requestError } = await ctx.admin
      .from("buyer_requests")
      .select("id,title,description,category_id,quantity,delivery_region,budget_min,budget_max,currency,created_at")
      .eq("visibility", "public")
      .eq("status", "open")
      .limit(100);
    if (requestError) throw requestError;

    const productText = [
      product.title,
      product.short_description,
      product.description,
      ...(Array.isArray(product.materials) ? product.materials : []),
      ...(Array.isArray(product.techniques) ? product.techniques : []),
    ].filter(Boolean).join(" ");
    const productTokens = tokens(productText);
    const artisanRegion = String(artisan.craft_region || artisan.state || "").toLowerCase();
    const productPrice = Number(product.price);
    const productCurrency = String(product.currency || "INR");

    const evaluated = (requests ?? []).map((request: Record<string, unknown>) => {
      let score = 0;
      const reasons: string[] = [];

      if (product.category_id && request.category_id === product.category_id) {
        score += 35;
        reasons.push("Same craft category");
      }

      const requestTokens = tokens(
        String(request.title ?? "") + " " + String(request.description ?? ""),
      );
      const overlap = [...productTokens].filter((token) => requestTokens.has(token));
      if (overlap.length) {
        const contribution = Math.min(30, overlap.length * 6);
        score += contribution;
        reasons.push("Product terms match buyer requirements: " + overlap.slice(0, 4).join(", "));
      }

      const requestedQty = Number(request.quantity ?? 1);
      if (Number(product.available_quantity) >= requestedQty) {
        score += 10;
        reasons.push("Available quantity meets the requested volume");
      }

      const deliveryRegion = String(request.delivery_region ?? "").toLowerCase();
      if (deliveryRegion && artisanRegion &&
          (deliveryRegion.includes(artisanRegion) || artisanRegion.includes(deliveryRegion))) {
        score += 15;
        reasons.push("Delivery region is compatible");
      }

      const buyerCurrency = String(request.currency ?? "INR");
      const min = request.budget_min == null ? null : Number(request.budget_min);
      const max = request.budget_max == null ? null : Number(request.budget_max);
      if (buyerCurrency === productCurrency &&
          (min == null || productPrice >= min) &&
          (max == null || productPrice <= max)) {
        score += 10;
        reasons.push("Listing price fits the stated buyer budget");
      }

      return {
        request,
        score: Math.min(100, score),
        reasons,
      };
    }).filter((item) => item.score >= 25)
      .sort((a, b) => b.score - a.score)
      .slice(0, 25);

    const rows = evaluated.map((item) => ({
      buyer_request_id: item.request.id,
      product_id: productId,
      match_score: item.score,
      match_reasons: item.reasons,
      status: "suggested",
    }));

    if (rows.length) {
      const { error: upsertError } = await ctx.admin
        .from("buyer_matches")
        .upsert(rows, { onConflict: "buyer_request_id,product_id" });
      if (upsertError) throw upsertError;
    }

    // Return only the public buyer brief. No buyer email, phone or personal profile data.
    return json({
      status: "ok",
      matching_method: "rules_based_v1",
      matches: evaluated.map((item) => ({
        buyer_request_id: item.request.id,
        title: item.request.title,
        description: item.request.description,
        quantity: item.request.quantity,
        delivery_region: item.request.delivery_region,
        budget_min: item.request.budget_min,
        budget_max: item.request.budget_max,
        currency: item.request.currency,
        match_score: item.score,
        match_reasons: item.reasons,
      })),
      message: "Initial matching uses category, text overlap, quantity, delivery region and stated budget. Semantic vector matching will be added after the embedding provider is configured.",
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "BUYER_MATCHING_FAILED";
    console.error("buyer-matching:", message);
    return json({ error: "BUYER_MATCHING_FAILED", message }, 500);
  }
});
