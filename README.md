# DARSH

**An AI-powered, direct-to-consumer creative marketplace for artisans and weavers.**

DARSH helps traditional makers create digital product identities, preserve the story behind their craft, reach buyers, understand evidence-based market comparisons and manage orders while retaining control over important decisions.

This repository is the Flutter application and Supabase backend for the DARSH MVP. It began as a fork of [Bagisto's open-source eCommerce mobile app](https://github.com/bagisto/opensource-ecommerce-mobile-app) (MIT License). Existing Flutter components are being reused and adapted; the active DARSH runtime uses Supabase rather than requiring a Bagisto/Laravel server.

## Current architecture

- **Flutter:** Android/iOS client, adapted from the upstream Bagisto Flutter storefront.
- **Supabase Auth:** email/password authentication and user sessions.
- **Supabase PostgreSQL:** artisan profiles, products, buyer requests, carts, orders, negotiations and agent cases.
- **Row Level Security:** user- and participant-scoped access to application tables.
- **Supabase Storage:** private intake/draft media and public media only after artisan-approved publication.
- **Supabase Edge Functions:** listing agent, price guidance, buyer matching, publication approvals and order workflow.

The database schema and Edge Function source are in `supabase/`. Supabase client configuration is centralised in `lib/core/supabase/darsh_supabase.dart`.

## MVP flows in progress

1. Sign up, sign in, password reset and session restoration.
2. Create and edit an artisan profile.
3. Create a product draft with photos, story, category, price, available stock and private minimum acceptable price.
4. Voice-first listing intake in Marathi, Hindi or English; image and transcript can be sent to the DARSH listing agent.
5. Review and edit AI suggestions before saving a draft.
6. Request publication and explicitly approve making the listing public.
7. Browse published products, maker profiles and craft categories.
8. Add products to a buyer cart and request an order.
9. Artisan approves or declines an order; stock is reserved only after acceptance.
10. View buyer and artisan orders.

## Development setup

### Requirements

- Flutter 3.50.1 (stable)
- Dart 3.14.0 or compatible SDK from the Flutter release
- Android Studio / Android SDK for Android development
- Xcode on macOS for iOS development

### Install

```bash
git clone https://github.com/shriramdawange/opensource-ecommerce-mobile-app.git
cd opensource-ecommerce-mobile-app
git checkout agent
flutter pub get
flutter gen-l10n
flutter run
```

DARSH uses compile-time configuration overrides:

```bash
flutter run \\
  --dart-define=ARTBOOK_SUPABASE_URL=https://<project-ref>.supabase.co \\
  --dart-define=ARTBOOK_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

The current development project URL and publishable key are configured as public-client defaults in the DARSH Supabase client file. A publishable key may be used in a mobile app only with properly configured RLS. **Never place a Supabase secret key or service-role key in Flutter code, build defines, assets or source control.**

## AI provider configuration

DARSH's listing agent defaults to OpenRouter's **free Google Gemma 4 26B A4B** model:

- Model: `google/gemma-4-26b-a4b-it:free`
- Base URL: `https://openrouter.ai/api/v1`
- Token price: $0 input / $0 output for the free variant

The only required Supabase Edge Function secret is:

- `ARTBOOK_LLM_API_KEY=<your private OpenRouter key>`

The base URL and model are defaults in the deployed Edge Function; `ARTBOOK_LLM_BASE_URL` and `ARTBOOK_LLM_MODEL` are optional server-side overrides. See [DARSH Supabase Setup](Docs/ARTBOOK_SUPABASE_SETUP.md).

Free-tier limits currently include 50 requests/day and 20 requests/minute; check OpenRouter's current limits before relying on this for a live pilot. Never put the OpenRouter key in Flutter, GitHub, or a committed `.env` file.

The agent keeps generated listings as drafts for artisan review and must not invent artisan identity, craft origin, materials, technique, heritage or provenance.
## Edge Functions

All deployed functions require a valid Supabase JWT:

| Function | Purpose |
|---|---|
| `darsh-agent` | Creates a durable case and an artisan-review listing draft |
| `save-listing-draft` | Saves the reviewed listing and private media references |
| `request-listing-publication` | Creates a publication approval |
| `agent-approval` | Executes an explicit approval; moves media to public storage only on publication |
| `price-guidance` | Produces indicative pricing from verified comparable observations |
| `buyer-matching` | Matches published products to public buyer briefs |
| `place-order` | Creates an order request after explicit buyer confirmation |

## MVP constraints (not yet production-ready)

- The AI provider secret must be configured before AI listing generation works.
- Buyer matching currently uses a transparent rules-based score; vector/embedding semantic matching is not yet implemented.
- Price guidance requires at least three recent, verified comparable observations. It returns `insufficient_data` rather than inventing a rate.
- Order requests currently support a single artisan and a single currency per cart.
- Payment capture, shipping calculation, tax calculation, refunds, fulfilment integrations and legal invoicing are not implemented.
- The marketplace requires real artisan onboarding and product data before it can demonstrate live inventory.
- Production release still needs final app identifiers, notification credentials, privacy policy, terms, payment/compliance review and security testing.

## Git workflow

- Development branch: `agent`
- Stable branch: `main`
- All implementation and fixes are made on `agent`.
- Review and test the branch before opening a pull request.
- **Do not merge into `main` without Shriram's explicit approval.**

## Upstream attribution

This project reuses and adapts the MIT-licensed [Bagisto Open Source eCommerce Mobile App](https://github.com/bagisto/opensource-ecommerce-mobile-app). The upstream code and its license notices are retained in the repository. DARSH-specific backend, data model, workflows and UI are being developed on the `agent` branch.
