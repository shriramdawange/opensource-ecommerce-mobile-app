# ArtBook Supabase Setup

## Project

- Project name: ArtBook
- Project ref: `csyazvpfgbulczbrfnpu`
- Region: Mumbai (`ap-south-1`)
- Plan at creation: Free
- URL: `https://csyazvpfgbulczbrfnpu.supabase.co`

The public publishable key is loaded by `lib/core/supabase/artbook_supabase.dart`. Keep secret/service-role keys on the Supabase server only.

## Required Edge Function secrets

AI listing generation requires an OpenAI-compatible provider. Set these secrets from Supabase Dashboard → Edge Functions → Secrets:

- `ARTBOOK_LLM_BASE_URL` — OpenAI-compatible chat completions endpoint
- `ARTBOOK_LLM_API_KEY` — private API key
- `ARTBOOK_LLM_MODEL` — model name accepted by that endpoint

Do not commit these values or put them in Flutter `--dart-define` arguments.

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
