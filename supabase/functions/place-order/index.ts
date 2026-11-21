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
function clean(value: unknown, limit = 300): string {
  return typeof value === "string" ? value.trim().slice(0, limit) : "";
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
    if (body.buyer_confirmed !== true) {
      return json({
        error: "BUYER_CONFIRMATION_REQUIRED",
        message: "The buyer must explicitly confirm sharing the shipping address and requesting the order.",
      }, 400);
    }

    const cartId = clean(body.cart_id, 80);
    const idempotencyKey = clean(body.idempotency_key, 100);
    const address = body.shipping_address ?? {};

    if (!cartId || !idempotencyKey) {
      return json({ error: "CART_AND_IDEMPOTENCY_KEY_REQUIRED" }, 400);
    }

    const shippingAddress = {
      recipient_name: clean(address.recipient_name, 120),
      phone: clean(address.phone, 32),
      line1: clean(address.line1, 180),
      line2: clean(address.line2, 180),
      city: clean(address.city, 100),
      state: clean(address.state, 100),
      postal_code: clean(address.postal_code, 20),
      country: clean(address.country, 80),
    };

    if (
      !shippingAddress.recipient_name || !shippingAddress.phone ||
      !shippingAddress.line1 || !shippingAddress.city ||
      !shippingAddress.state || !shippingAddress.postal_code ||
      !shippingAddress.country
    ) {
      return json({ error: "SHIPPING_ADDRESS_INCOMPLETE" }, 400);
    }

    const { data, error } = await ctx.admin.rpc("artbook_create_order", {
      p_cart_id: cartId,
      p_buyer_user_id: ctx.user.id,
      p_shipping_address: shippingAddress,
      p_idempotency_key: idempotencyKey,
    });

    if (error) {
      const message = error.message ?? "ORDER_REQUEST_FAILED";
      const known = [
        "CART_NOT_FOUND_OR_NOT_OWNED",
        "CART_EMPTY",
        "MULTI_ARTISAN_CART_NOT_SUPPORTED",
        "INSUFFICIENT_STOCK",
        "PRODUCT_NOT_PUBLISHED",
        "MINIMUM_ORDER_QUANTITY_NOT_MET",
        "CANNOT_BUY_OWN_PRODUCT",
        "MIXED_CURRENCY_CART_NOT_SUPPORTED",
        "SHIPPING_ADDRESS_INCOMPLETE",
      ];
      const match = known.find((code) => message.includes(code));
      return json({
        error: match ?? "ORDER_REQUEST_FAILED",
        message: match ?? "The order could not be created. Please review your cart and try again.",
      }, match ? 409 : 500);
    }

    return json({
      ...data,
      buyer_message: "Your order request has been sent to the artisan for approval. No payment has been captured.",
      payment_captured: false,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "ORDER_REQUEST_FAILED";
    console.error("place-order:", message);
    return json({ error: "ORDER_REQUEST_FAILED" }, 500);
  }
});
