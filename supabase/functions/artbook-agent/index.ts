import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function readNamedKey(singleNames: string[], mapName: string): string | null {
  for (const name of singleNames) {
    const value = Deno.env.get(name);
    if (value) return value;
  }
  const raw = Deno.env.get(mapName);
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      if (typeof parsed.default === "string") return parsed.default;
    } catch {
      // Ignore malformed optional key map.
    }
  }
  return null;
}

async function getContext(req: Request) {
  const url = Deno.env.get("SUPABASE_URL");
  const publishable = readNamedKey(
    ["SUPABASE_PUBLISHABLE_KEY", "SUPABASE_ANON_KEY"],
    "SUPABASE_PUBLISHABLE_KEYS",
  );
  const secret = readNamedKey(
    ["SUPABASE_SECRET_KEY", "SUPABASE_SERVICE_ROLE_KEY"],
    "SUPABASE_SECRET_KEYS",
  );
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");

  if (!url || !publishable || !secret) {
    throw new Error("SUPABASE_SERVER_CONFIGURATION_MISSING");
  }
  if (!token || token === authHeader) {
    throw new Error("UNAUTHENTICATED");
  }

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

function safeString(value: unknown, max: number): string {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

function encodeStoragePath(path: string): string {
  return path.split("/").map(encodeURIComponent).join("/");
}

async function callModel(input: {
  transcript: string;
  artisanNotes: string;
  language: string;
  imageUrls: string[];
}) {
  const endpoint = Deno.env.get("ARTBOOK_LLM_BASE_URL");
  const apiKey = Deno.env.get("ARTBOOK_LLM_API_KEY");
  const model = Deno.env.get("ARTBOOK_LLM_MODEL");

  if (!endpoint || !apiKey || !model) {
    throw new Error("ARTBOOK_AI_PROVIDER_NOT_CONFIGURED");
  }

  const systemPrompt = [
    "You are ArtBook's artisan listing assistant.",
    "Return one valid JSON object only.",
    "Create a useful product-listing draft from the artisan's own transcript, notes, and visible image evidence.",
    "Never invent the artisan's name, village, state, craft lineage, materials, technique, age, provenance, certification, or cultural origin.",
    "If a fact is not supplied or not clearly visible, use null or an empty array and add it to uncertainties.",
    "Do not guess market price, buyer demand, authenticity, or legal compliance.",
    "Keep artisan-provided facts separate from visual observations and AI suggestions.",
    "Preserve the artisan's meaning and answer in the requested language where possible.",
    'JSON shape: {"title":string,"short_description":string,"description":string,"craft_story":string,"craft_type_suggestion":string|null,"materials_suggestions":string[],"technique_suggestions":string[],"craft_origin_suggestion":string|null,"tags":string[],"uncertainties":string[]}.',
  ].join(" ");

  const content: Array<Record<string, unknown>> = [{
    type: "text",
    text: [
      "Requested language: " + input.language,
      "Artisan voice transcript: " + (input.transcript || "(not provided)"),
      "Additional artisan notes: " + (input.artisanNotes || "(not provided)"),
      "Prepare a draft only. Do not publish or make any commitments.",
    ].join("\n"),
  }];
  for (const url of input.imageUrls) {
    content.push({ type: "image_url", image_url: { url } });
  }

  let lastError = "MODEL_REQUEST_FAILED";
  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Authorization": "Bearer " + apiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model,
          temperature: 0.2,
          response_format: { type: "json_object" },
          messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content },
          ],
        }),
        signal: AbortSignal.timeout(25000),
      });

      if (!response.ok) {
        lastError = "MODEL_HTTP_" + response.status;
        if (response.status !== 429 && response.status < 500) break;
        await new Promise((resolve) => setTimeout(resolve, 400 * (attempt + 1)));
        continue;
      }

      const payload = await response.json();
      const text = payload?.choices?.[0]?.message?.content;
      if (typeof text !== "string") throw new Error("MODEL_EMPTY_RESPONSE");
      const draft = JSON.parse(text);

      const stringField = (key: string, max: number) =>
        safeString(draft[key], max);
      const arrayField = (key: string) =>
        Array.isArray(draft[key])
          ? draft[key].filter((item: unknown) => typeof item === "string")
              .map((item: string) => item.trim().slice(0, 80)).slice(0, 20)
          : [];

      return {
        title: stringField("title", 140),
        short_description: stringField("short_description", 300),
        description: stringField("description", 4000),
        craft_story: stringField("craft_story", 4000),
        craft_type_suggestion: draft.craft_type_suggestion == null
          ? null : safeString(draft.craft_type_suggestion, 100),
        materials_suggestions: arrayField("materials_suggestions"),
        technique_suggestions: arrayField("technique_suggestions"),
        craft_origin_suggestion: draft.craft_origin_suggestion == null
          ? null : safeString(draft.craft_origin_suggestion, 160),
        tags: arrayField("tags"),
        uncertainties: arrayField("uncertainties"),
      };
    } catch (error) {
      lastError = error instanceof Error ? error.message : "MODEL_REQUEST_FAILED";
      if (lastError === "ARTBOOK_AI_PROVIDER_NOT_CONFIGURED") throw error;
      await new Promise((resolve) => setTimeout(resolve, 400 * (attempt + 1)));
    }
  }
  throw new Error(lastError);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "METHOD_NOT_ALLOWED" }, 405);

  let context: Awaited<ReturnType<typeof getContext>>;
  try {
    context = await getContext(req);
  } catch (error) {
    const message = error instanceof Error ? error.message : "UNAUTHENTICATED";
    return json({ error: message }, message === "UNAUTHENTICATED" ? 401 : 503);
  }

  const { admin, user } = context;
  let caseId: string | null = null;

  try {
    const body = await req.json();
    if (body?.action !== "start_listing") {
      return json({ error: "UNSUPPORTED_ACTION" }, 400);
    }

    const input = body.input ?? {};
    let language = safeString(input.language, 16) || "en-IN";
    let transcript = safeString(input.voice_transcript, 8000);
    let artisanNotes = safeString(input.artisan_notes, 4000);
    let mediaPaths = Array.isArray(input.media_paths)
      ? input.media_paths.filter((p: unknown) => typeof p === "string").slice(0, 4)
      : [];
    const idempotencyKey = safeString(body.idempotency_key, 100) || null;
    let attempt = 1;

    if (!transcript && !artisanNotes && mediaPaths.length === 0) {
      return json({ error: "LISTING_INPUT_REQUIRED" }, 400);
    }
    if (mediaPaths.some((path: string) => !path.startsWith(user.id + "/"))) {
      return json({ error: "MEDIA_PATH_NOT_OWNED_BY_USER" }, 403);
    }

    let existingCase: Record<string, unknown> | null = null;
    if (idempotencyKey) {
      const { data: found, error: findError } = await admin
        .from("agent_cases")
        .select("id,status,current_step,context,input_payload,retry_count,next_retry_at")
        .eq("owner_user_id", user.id)
        .eq("idempotency_key", idempotencyKey)
        .maybeSingle();
      if (findError) throw findError;
      existingCase = found as Record<string, unknown> | null;
    }

    if (existingCase) {
      const existingStatus = String(existingCase.status ?? "");
      const existingContext = (existingCase.context ?? {}) as Record<string, unknown>;
      if (existingStatus === "awaiting_artisan_review" || existingStatus === "completed") {
        return json({
          case_id: existingCase.id,
          status: existingStatus,
          step: existingCase.current_step,
          draft: existingContext.listing_draft ?? null,
          idempotent_replay: true,
        });
      }
      if (existingStatus === "running") {
        return json({
          case_id: existingCase.id,
          status: "running",
          step: existingCase.current_step,
          message: "This agent case is already running. Check its status before starting another run.",
        }, 202);
      }
      if (existingStatus !== "failed") {
        return json({
          error: "AGENT_CASE_NOT_RESUMABLE",
          case_id: existingCase.id,
          status: existingStatus,
        }, 409);
      }

      const previousAttempts = Number(existingCase.retry_count ?? 0);
      if (previousAttempts >= 3) {
        return json({
          error: "AGENT_RETRY_LIMIT_REACHED",
          case_id: existingCase.id,
          status: "failed",
          message: "This case reached its automatic retry limit. Start a new listing case or contact support.",
        }, 409);
      }

      const nextRetryAt = existingCase.next_retry_at
        ? Date.parse(String(existingCase.next_retry_at))
        : 0;
      if (Number.isFinite(nextRetryAt) && nextRetryAt > Date.now()) {
        return json({
          error: "AGENT_RETRY_BACKOFF",
          case_id: existingCase.id,
          status: "failed",
          retry_after: new Date(nextRetryAt).toISOString(),
          message: "This case is saved and can be retried after the short recovery interval.",
        }, 429);
      }

      const savedInput = (existingCase.input_payload ?? {}) as Record<string, unknown>;
      language = safeString(savedInput.language, 16) || language;
      transcript = safeString(savedInput.transcript, 8000) || transcript;
      artisanNotes = safeString(savedInput.artisan_notes, 4000) || artisanNotes;
      mediaPaths = Array.isArray(savedInput.media_paths)
        ? savedInput.media_paths.filter((path: unknown) => typeof path === "string").slice(0, 4)
        : mediaPaths;

      attempt = previousAttempts + 1;
      caseId = String(existingCase.id);

      const { error: resumeError } = await admin
        .from("agent_cases")
        .update({
          status: "running",
          current_step: "understand_craft",
          next_retry_at: null,
          last_error_code: null,
        })
        .eq("id", caseId)
        .eq("owner_user_id", user.id);
      if (resumeError) throw resumeError;
    } else {
      const { data: artisan } = await admin
        .from("artisan_profiles").select("id")
        .eq("user_id", user.id).maybeSingle();

      const { data: createdCase, error: caseError } = await admin
        .from("agent_cases")
        .insert({
          owner_user_id: user.id,
          artisan_profile_id: artisan?.id ?? null,
          case_type: "listing_creation",
          status: "running",
          current_step: "understand_craft",
          input_payload: {
            language,
            transcript,
            artisan_notes: artisanNotes,
            media_paths: mediaPaths,
          },
          context: { language, transcript, artisan_notes: artisanNotes, media_paths: mediaPaths },
          retry_count: 0,
          idempotency_key: idempotencyKey,
        })
        .select("id").single();

      if (caseError || !createdCase) throw caseError ?? new Error("CASE_CREATE_FAILED");
      caseId = createdCase.id;
    }

    const { data: step, error: stepError } = await admin
      .from("agent_case_steps")
      .insert({
        case_id: caseId,
        step_key: "understand_craft",
        status: "running",
        attempt,
        input_payload: { language, transcript, artisan_notes: artisanNotes, media_paths: mediaPaths },
        started_at: new Date().toISOString(),
      })
      .select("id").single();

    if (stepError || !step) throw stepError ?? new Error("CASE_STEP_CREATE_FAILED");

    const imageUrls: string[] = [];
    for (const path of mediaPaths) {
      const { data: signed, error: signedError } = await admin.storage
        .from("artbook-agent-intake")
        .createSignedUrl(path, 90);
      if (signedError || !signed?.signedUrl) {
        throw new Error("PRIVATE_MEDIA_ACCESS_FAILED");
      }
      imageUrls.push(signed.signedUrl);
    }

    try {
      const draft = await callModel({ transcript, artisanNotes, language, imageUrls });
      if (!draft.title) {
        throw new Error("MODEL_DRAFT_MISSING_TITLE");
      }

      await admin.from("agent_case_steps").update({
        status: "succeeded",
        output_payload: draft,
        completed_at: new Date().toISOString(),
      }).eq("id", step.id);

      await admin.from("agent_cases").update({
        status: "awaiting_artisan_review",
        current_step: "artisan_review",
        context: {
          language,
          transcript,
          artisan_notes: artisanNotes,
          media_paths: mediaPaths,
          listing_draft: draft,
          review_required: true,
        },
      }).eq("id", caseId);

      return json({
        case_id: caseId,
        status: "awaiting_artisan_review",
        step: "artisan_review",
        draft,
        requires_artisan_review: true,
        message: "Review and edit every suggested detail before saving a product draft.",
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "MODEL_REQUEST_FAILED";
      await admin.from("agent_case_steps").update({
        status: "failed",
        error_code: message,
        error_message: "The listing draft could not be generated.",
        completed_at: new Date().toISOString(),
      }).eq("id", step.id);
      await admin.from("agent_cases").update({
        status: "failed",
        current_step: "understand_craft",
        retry_count: attempt,
        last_error_code: message,
        next_retry_at: new Date(
          Date.now() + Math.min(4, 2 ** (attempt - 1)) * 60000,
        ).toISOString(),
      }).eq("id", caseId);

      const status = message === "ARTBOOK_AI_PROVIDER_NOT_CONFIGURED" ? 503 : 502;
      return json({
        error: message,
        case_id: caseId,
        resumable: true,
        message: message === "ARTBOOK_AI_PROVIDER_NOT_CONFIGURED"
          ? "Set ARTBOOK_LLM_BASE_URL, ARTBOOK_LLM_API_KEY and ARTBOOK_LLM_MODEL in Edge Function secrets."
          : "The AI step failed. The case was saved and can be retried.",
      }, status);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "AGENT_REQUEST_FAILED";
    if (caseId) {
      await admin.from("agent_cases").update({
        status: "failed",
        last_error_code: message,
      }).eq("id", caseId);
    }
    return json({ error: message }, 400);
  }
});
