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
    const approvalId = typeof body.approval_id === "string" ? body.approval_id : "";
    const decision = body.decision === "approve" || body.decision === "reject"
      ? body.decision
      : "";

    if (!approvalId || !decision) {
      return json({ error: "APPROVAL_ID_AND_VALID_DECISION_REQUIRED" }, 400);
    }

    // If the artisan is approving publication, move private draft media
    // into the public product bucket before the product becomes visible.
    const movedMedia: Array<{ id: string; oldPath: string; newPath: string }> = [];
    let publishProductId: string | null = null;

    if (decision === "approve") {
      const { data: approval, error: approvalReadError } = await ctx.admin
        .from("agent_approvals")
        .select("id,owner_user_id,action_type,status,payload")
        .eq("id", approvalId)
        .maybeSingle();

      if (approvalReadError || !approval) {
        return json({ error: "APPROVAL_NOT_FOUND" }, 404);
      }
      if (approval.owner_user_id !== ctx.user.id) {
        return json({ error: "APPROVAL_NOT_OWNED_BY_USER" }, 403);
      }
      if (approval.status !== "pending") {
        return json({ error: "APPROVAL_NOT_PENDING" }, 409);
      }

      if (approval.action_type === "publish_listing") {
        publishProductId = String(approval.payload?.product_id ?? "");
        if (!publishProductId) return json({ error: "PRODUCT_ID_REQUIRED" }, 400);

        const { data: mediaRows, error: mediaReadError } = await ctx.admin
          .from("product_media")
          .select("id,storage_path,storage_bucket")
          .eq("product_id", publishProductId);

        if (mediaReadError) throw mediaReadError;

        for (const media of mediaRows ?? []) {
          const oldBucket = String(media.storage_bucket ?? "artbook-product-media");
          const oldPath = String(media.storage_path);
          if (oldBucket !== "artbook-agent-intake") continue;

          if (!oldPath.startsWith(ctx.user.id + "/")) {
            throw new Error("PRIVATE_MEDIA_NOT_OWNED_BY_ARTISAN");
          }

          const { data: blob, error: downloadError } = await ctx.admin.storage
            .from("artbook-agent-intake")
            .download(oldPath);
          if (downloadError || !blob) throw new Error("PRIVATE_MEDIA_DOWNLOAD_FAILED");

          const safeName = oldPath.split("/").pop() ?? "craft-image";
          const newPath = ctx.user.id + "/" + publishProductId + "/" +
            crypto.randomUUID() + "-" + safeName;

          const { error: uploadError } = await ctx.admin.storage
            .from("artbook-product-media")
            .upload(newPath, new Uint8Array(await blob.arrayBuffer()), {
              contentType: blob.type || "image/jpeg",
              upsert: false,
            });
          if (uploadError) throw new Error("PUBLIC_MEDIA_UPLOAD_FAILED");

          const { error: updateMediaError } = await ctx.admin
            .from("product_media")
            .update({
              storage_path: newPath,
              storage_bucket: "artbook-product-media",
            })
            .eq("id", media.id);
          if (updateMediaError) {
            await ctx.admin.storage.from("artbook-product-media").remove([newPath]);
            throw updateMediaError;
          }

          movedMedia.push({ id: String(media.id), oldPath, newPath });
        }
      }
    }

    const { data, error } = await ctx.admin.rpc("artbook_decide_approval", {
      p_approval_id: approvalId,
      p_owner_user_id: ctx.user.id,
      p_decision: decision,
    });

    if (error) {
      // Compensate the storage copy if the approval transaction failed.
      for (const moved of movedMedia.reverse()) {
        await ctx.admin.from("product_media").update({
          storage_path: moved.oldPath,
          storage_bucket: "artbook-agent-intake",
        }).eq("id", moved.id);
        await ctx.admin.storage.from("artbook-product-media").remove([moved.newPath]);
      }
      const message = error.message ?? "APPROVAL_FAILED";
      const known = [
        "APPROVAL_NOT_FOUND",
        "APPROVAL_NOT_OWNED_BY_USER",
        "APPROVAL_NOT_PENDING",
        "APPROVAL_PAYLOAD_HASH_MISMATCH",
        "ORDER_NOT_FOUND",
        "ARTISAN_NOT_AUTHORIZED",
        "ORDER_NOT_PENDING_APPROVAL",
        "INSUFFICIENT_STOCK",
        "ORDER_BELOW_ARTISAN_FLOOR",
        "PRODUCT_NOT_FOUND",
        "PRODUCT_NOT_OWNED_BY_USER",
        "PRODUCT_NOT_READY_TO_PUBLISH",
        "LISTING_PRICE_BELOW_ARTISAN_FLOOR",
        "APPROVAL_ACTION_NOT_IMPLEMENTED",
      ];
      const code = known.find((item) => message.includes(item));
      return json({
        error: code ?? "APPROVAL_FAILED",
        message: code ?? "The approval could not be completed.",
      }, code ? 409 : 500);
    }

    // Remove private draft copies only after the approval transaction succeeded.
    if (decision === "approve" && publishProductId && movedMedia.length > 0) {
      const oldPaths = movedMedia.map((item) => item.oldPath);
      await ctx.admin.storage.from("artbook-agent-intake").remove(oldPaths);
    }

    return json(data);
  } catch (error) {
    const message = error instanceof Error ? error.message : "APPROVAL_FAILED";
    console.error("agent-approval:", message);
    return json({ error: "APPROVAL_FAILED" }, 500);
  }
});
