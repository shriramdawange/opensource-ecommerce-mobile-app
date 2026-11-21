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

    const { data, error } = await ctx.admin.rpc("artbook_request_listing_publication", {
      p_product_id: productId,
      p_artisan_user_id: ctx.user.id,
    });
    if (error) {
      const message = error.message ?? "PUBLICATION_REQUEST_FAILED";
      const code = [
        "PRODUCT_NOT_FOUND",
        "PRODUCT_NOT_OWNED_BY_USER",
        "PRODUCT_NOT_READY_TO_PUBLISH",
        "LISTING_PRICE_BELOW_ARTISAN_FLOOR",
      ].find((item) => message.includes(item));
      return json({ error: code ?? "PUBLICATION_REQUEST_FAILED" }, code ? 409 : 500);
    }

    return json({
      ...data,
      message: "Review the product and explicitly approve publication to make it visible to buyers.",
    });
  } catch (error) {
    console.error("request-listing-publication:", error);
    return json({ error: "PUBLICATION_REQUEST_FAILED" }, 500);
  }
});
