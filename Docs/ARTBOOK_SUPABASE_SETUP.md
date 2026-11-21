# ArtBook Supabase Setup

## Project

- Project name: ArtBook
- Project ref: `csyazvpfgbulczbrfnpu`
- Region: Mumbai (`ap-south-1`)
- Plan at creation: Free
- URL: `https://csyazvpfgbulczbrfnpu.supabase.co`

The public publishable key is loaded by `lib/core/supabase/artbook_supabase.dart`. Keep secret/service-role keys on the Supabase server only.

## OpenRouter configuration for ArtBook Agentic AI

The ArtBook MVP now defaults to **Google Gemma 4 26B A4B (free)** through OpenRouter.

- Model ID: `google/gemma-4-26b-a4b-it:free`
- Token price: **$0 input / $0 output** on the free variant
- Image + text input
- JSON structured output (JSON-object mode; not strict JSON-schema enforcement)
- Native function-calling capability is supported by the model, although the current ArtBook listing call uses a single structured generation request rather than model-driven tool execution.

OpenRouter currently documents free variants as limited to **20 requests per minute and 50 requests per day** for accounts that have not purchased credits. Failed requests can also count against the daily allowance. These limits can change and free providers may be busy or temporarily unavailable.

### Required setup — one secret only

1. Create a dedicated API key at [OpenRouter Keys](https://openrouter.ai/settings/keys).
2. Open [ArtBook Edge Function Secrets](https://supabase.com/dashboard/project/csyazvpfgbulczbrfnpu/functions/secrets).
3. Add this one secret:

| Secret name | Value |
|---|---|
| `ARTBOOK_LLM_API_KEY` | Your private OpenRouter key (starts with `sk-or-v1-`) |

The deployed `artbook-agent` function already defaults to:
- Base URL: `https://openrouter.ai/api/v1`
- Model: `google/gemma-4-26b-a4b-it:free`

You do **not** need to add `ARTBOOK_LLM_BASE_URL` or `ARTBOOK_LLM_MODEL` for the default MVP. Those remain optional server-side overrides for future model changes.

### Security and budget

- Enter the key only in Supabase Edge Function Secrets. Do not paste it into ChatGPT, Flutter, GitHub, screenshots, or a committed `.env` file.
- Never use a Supabase secret/service-role key as the OpenRouter key.
- Never expose `ARTBOOK_LLM_API_KEY` to the mobile application.
- The free model does not require purchasing OpenRouter credits. Do not add credits just to test this setup.
- Keep model/provider data handling in mind: do not send sensitive personal information or unnecessary identifying details in artisan descriptions or photographs.

For local development only, use `supabase/functions/.env` (never commit it). The safe placeholder template is in `supabase/functions/.env.example`.

Every deployed ArtBook Edge Function continues to require JWT verification.
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
