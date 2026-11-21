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
function clean(value: unknown, max = 4000): string {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}
function stringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item) => typeof item === "string")
    .map((item) => item.trim().slice(0, 100))
    .filter(Boolean).slice(0, 20);
}
function safeSlug(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 80) || "handmade-product";
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
    const caseId = clean(body.case_id, 80);
    const title = clean(body.title, 140);
    const price = Number(body.price);
    const floorPrice = body.floor_price == null || body.floor_price === ""
      ? null : Number(body.floor_price);
    const categoryId = clean(body.category_id, 80);
    const quantity = Number(body.available_quantity ?? 1);
    const minOrderQuantity = Number(body.min_order_quantity ?? 1);
    const mediaPaths = Array.isArray(body.media_paths)
      ? body.media_paths.filter((path: unknown) => typeof path === "string").slice(0, 4)
      : [];

    if (!caseId || !title || !Number.isFinite(price) || price <= 0 ||
        !Number.isInteger(quantity) || quantity < 0 ||
        !Number.isInteger(minOrderQuantity) || minOrderQuantity < 1) {
      return json({ error: "INVALID_LISTING_FIELDS" }, 400);
    }
    if (floorPrice !== null && (!Number.isFinite(floorPrice) || floorPrice < 0 || floorPrice > price)) {
      return json({ error: "INVALID_ARTISAN_FLOOR_PRICE" }, 400);
    }
    if (mediaPaths.some((path: string) => !path.startsWith(ctx.user.id + "/"))) {
      return json({ error: "MEDIA_PATH_NOT_OWNED_BY_USER" }, 403);
    }

    const { data: agentCase, error: caseError } = await ctx.admin
      .from("agent_cases")
      .select("id,owner_user_id,artisan_profile_id,case_type,status,context")
      .eq("id", caseId).maybeSingle();

    if (caseError || !agentCase) return json({ error: "AGENT_CASE_NOT_FOUND" }, 404);
    if (agentCase.owner_user_id !== ctx.user.id) return json({ error: "AGENT_CASE_NOT_OWNED" }, 403);
    if (agentCase.case_type !== "listing_creation" ||
        agentCase.status !== "awaiting_artisan_review") {
      return json({ error: "AGENT_CASE_NOT_READY_FOR_DRAFT_SAVE" }, 409);
    }

    const { data: artisan } = await ctx.admin
      .from("artisan_profiles").select("id")
      .eq("user_id", ctx.user.id).maybeSingle();
    if (!artisan) return json({ error: "ARTISAN_PROFILE_REQUIRED" }, 409);

    if (categoryId) {
      const { data: category } = await ctx.admin
        .from("craft_categories").select("id")
        .eq("id", categoryId).eq("is_active", true).maybeSingle();
      if (!category) return json({ error: "INVALID_CRAFT_CATEGORY" }, 400);
    }

    const materials = stringArray(body.materials);
    const techniques = stringArray(body.techniques);
    const aiDraft = agentCase.context?.listing_draft ?? {};
    const slug = safeSlug(title) + "-" + crypto.randomUUID().slice(0, 8);

    const { data: product, error: productError } = await ctx.admin
      .from("products")
      .insert({
        artisan_profile_id: artisan.id,
        category_id: categoryId || null,
        title,
        slug,
        short_description: clean(body.short_description, 300),
        description: clean(body.description, 4000),
        craft_story: clean(body.craft_story, 4000),
        craft_origin: clean(body.craft_origin, 160),
        materials,
        techniques,
        price,
        currency: "INR",
        available_quantity: quantity,
        min_order_quantity: minOrderQuantity,
        status: "draft",
        is_handmade: true,
        ai_generated_fields: {
          source_agent_case_id: caseId,
          ai_suggestions: aiDraft,
          artisan_reviewed: true,
        },
      })
      .select("id,title,price,currency,status,available_quantity,min_order_quantity")
      .single();

    if (productError || !product) throw productError ?? new Error("PRODUCT_DRAFT_CREATE_FAILED");

    if (floorPrice !== null) {
      const { error: termsError } = await ctx.admin
        .from("product_private_terms")
        .upsert({
          product_id: product.id,
          artisan_user_id: ctx.user.id,
          floor_price: floorPrice,
        });
      if (termsError) throw termsError;
    }

    if (mediaPaths.length) {
      const mediaRows = mediaPaths.map((path: string, index: number) => ({
        product_id: product.id,
        storage_path: path,
        storage_bucket: "artbook-agent-intake",
        media_type: "image",
        is_primary: index === 0,
        sort_order: index,
        alt_text: title,
      }));
      const { error: mediaError } = await ctx.admin.from("product_media").insert(mediaRows);
      if (mediaError) throw mediaError;
    }

    const { error: updateError } = await ctx.admin.from("agent_cases").update({
      product_id: product.id,
      status: "completed",
      current_step: "draft_saved",
      context: {
        ...(agentCase.context ?? {}),
        artisan_reviewed: true,
        saved_product_id: product.id,
      },
    }).eq("id", caseId);
    if (updateError) throw updateError;

    return json({
      status: "draft_saved",
      product,
      message: "Your product is saved as a private draft. It is not visible to buyers until you explicitly request publication.",
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "LISTING_DRAFT_SAVE_FAILED";
    console.error("save-listing-draft:", message);
    return json({ error: "LISTING_DRAFT_SAVE_FAILED", message }, 500);
  }
});
