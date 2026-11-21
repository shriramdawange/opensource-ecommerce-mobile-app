# ArtBook backend integration plan

## Repository facts
- This repository is a fork of `bagisto/opensource-ecommerce-mobile-app` and its upstream license is MIT.
- It is a Flutter customer storefront. Its current client is wired to Bagisto GraphQL, including `lib/core/graphql/`, `GraphQLClientProvider`, `bagistoEndpoint`, and `storefrontKey`.
- Existing screens and repositories cover catalog, categories, cart, checkout, account, orders and reviews. Reuse these where the ArtBook product model fits; do not replace working UI wholesale.

## Architecture decision
- Keep Flutter as the presentation/client layer.
- Use Supabase Postgres as the source of truth, Supabase Auth for identity, Supabase Storage for product media, RLS for authorization, and Supabase Edge Functions for privileged/domain workflows.
- Do not put Supabase service-role/secret keys in Flutter.
- Do not assume Bagisto GraphQL queries can simply be redirected to Supabase. Introduce typed repositories/data sources and explicit mapping from ArtBook REST/Data API responses to existing Dart models. Gradually replace feature repositories instead of rewriting every screen at once.

## Initial ArtBook domain
- profiles and artisan_profiles
- craft_categories and craft_taxonomy
- products, product_media, product_stories
- price_observations / price_guidance (indicative only, with source and timestamp)
- buyer_profiles and buyer_interests
- buyer_matches
- negotiation_cases and negotiation_messages
- orders and order_events
- agent_cases and agent_steps (durable state, retry counts, tool outputs, approval status)
- consent/audit events

## Agentic workflow
1. Artisan submits voice note and photos.
2. Create durable agent case and store media.
3. Speech/image understanding produces a draft product/craft profile.
4. Generate a story-rich listing; keep provenance and artisan-provided facts separate from AI suggestions.
5. Produce indicative price range only from recorded comparable observations; never invent a rate.
6. Match buyer requirements semantically.
7. Draft negotiation above artisan's explicit floor price.
8. Require explicit artisan approval before publishing an offer, accepting an order, payment, legal commitment, or sharing personal data.
9. Persist every step; retry transient failures with bounded backoff; resume cases safely/idempotently.

## Security and quality
- RLS on all exposed tables; default deny.
- Artisan can edit own profile/products/cases; buyer can read published products and own buyer data/orders.
- Storage paths scoped by authenticated user and role.
- Validate uploads, size, MIME and image dimensions.
- Server-side validate ownership, price floors, order states and approval tokens.
- No payment capture or legally binding action without explicit confirmation.
- Keep audit trail for sensitive decisions.
- Add SQL migration tests, Edge Function tests and Flutter repository/model tests.

## Delivery phases
A. Inspect current Flutter architecture and map existing models/repositories.
B. Build Supabase schema + RLS + Storage buckets on a dedicated ArtBook Supabase project/branch.
C. Implement Auth/profile/catalog/media/order Edge Functions.
D. Add Flutter Supabase client and adapter repositories feature-by-feature.
E. Implement durable agent-case workflow and AI tool adapters.
F. Add integration tests, Flutter analyze/test, and demo flow.
G. Open PR to main for review; do not merge without Shriram's explicit permission.

## Not yet confirmed
- Which Supabase project belongs to ArtBook (the connected projects did not identify one).
- Whether the current MVP scope needs customer checkout/payment or only artisan catalogue + buyer lead/negotiation.
- AI model/provider and credentials are not committed; use server-side environment secrets.
