# ArtBook Supabase Setup

## Project

- Project name: ArtBook
- Project ref: `csyazvpfgbulczbrfnpu`
- Region: Mumbai (`ap-south-1`)
- Plan at creation: Free
- URL: `https://csyazvpfgbulczbrfnpu.supabase.co`

The public publishable key is loaded by `lib/core/supabase/artbook_supabase.dart`. Keep secret/service-role keys on the Supabase server only.

## OpenRouter configuration for ArtBook Agentic AI

Recommended MVP model: **`meta/muse-ember`**. It accepts text and images, supports structured outputs, and is designed for agent-style workloads. OpenRouter currently lists it at **$0.10 per 1M input tokens** and **$0.50 per 1M output tokens**. Prices can change; check the live model page before scaling.

Create a dedicated OpenRouter API key for ArtBook at [OpenRouter Keys](https://openrouter.ai/settings/keys). If per-key budget controls are available on your plan, start with a small cap (for example, **$5/month**) and limit the key to `meta/muse-ember` where model allowlisting is available. If your plan does not expose per-key budgets, keep a small prepaid credit balance and monitor usage in OpenRouter Activity.

Then open [ArtBook Edge Function Secrets](https://supabase.com/dashboard/project/csyazvpfgbulczbrfnpu/functions/secrets) and set these three values:

| Secret name | Value |
|---|---|
| `ARTBOOK_LLM_BASE_URL` | `https://openrouter.ai/api/v1` |
| `ARTBOOK_LLM_API_KEY` | Your OpenRouter key (starts with `sk-or-v1-`) |
| `ARTBOOK_LLM_MODEL` | `meta/muse-ember` |

The `artbook-agent` function appends `/chat/completions` to the base URL (or accepts a full endpoint URL), sends the key as a Bearer token, and caps the generated response at 1,200 tokens. It labels requests as ArtBook using the optional OpenRouter `HTTP-Referer` and `X-Title` headers.

**Security rules:**
- Enter the API key only in Supabase Edge Function Secrets. Do not paste it into ChatGPT, Flutter, GitHub, screenshots, or a committed `.env` file.
- Do not use a Supabase secret/service-role key as the OpenRouter key.
- Do not expose `ARTBOOK_LLM_API_KEY` to the mobile app. Only the Edge Function reads it.
- Keep a strict OpenRouter spend cap during testing. Check usage after a few listing generations.

Secrets are available to Edge Functions immediately after saving; no separate function redeploy is normally required for secret changes.

For local development only, use `supabase/functions/.env` (never commit it). A safe placeholder template is in `supabase/functions/.env.example`.

The Supabase Edge Functions use Supabase-provided project URL and server keys. Every function is configured with JWT verification enabled.

## Storage buckets

| Bucket | Visibility | Use |
|---|---|---|
| `artbook-agent-intake` | Private | Artisan draft/intake images before approval |
| `artbook-product-media` | Public | Product media after artisan approves publication |
| `artbook-artisan-avatars` | Public | Public artisan avatar images |

Private intake objects use the authenticated user's UUID as the first path segment. The publication approval function copies the approved product's media to the public product bucket and updates the media record; it then removes the private copies.

## Database safety

- All ArtBook tables in the public schema have RLS enabled.
- Product publication is server-controlled; the Flutter client cannot directly set a product to `published`.
- The artisan's floor price is stored in `product_private_terms` and is not exposed to buyers.
- Order creation requires explicit buyer confirmation and starts in `pending_approval`.
- Stock is reserved only when the artisan accepts the order.
- No payment is captured by the current MVP.

## Current remote migration history

The live project has the initial schema, index/grant hardening, order workflow, listing publication approval and private draft media applied. The deployed Edge Function sources are versioned under `supabase/functions/`. Before using Supabase CLI to push schema changes, reconcile local migration files with the live migration history; do not run a fresh schema against this already-initialised project.
