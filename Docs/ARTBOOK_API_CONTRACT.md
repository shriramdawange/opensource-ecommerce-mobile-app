# ArtBook API Contract (MVP draft)

Base: Supabase project URL. Public client uses publishable key; authenticated requests use Supabase Auth JWT. All privileged operations execute in Edge Functions. This contract is a starting point and must be reconciled against the selected ArtBook Supabase project before implementation.

## Auth and profile
- Supabase Auth sign-up/sign-in/sign-out.
- `GET /rest/v1/profiles?id=eq.<auth.uid>`
- `PATCH /rest/v1/profiles?id=eq.<auth.uid>`
- `GET /rest/v1/artisan_profiles?user_id=eq.<auth.uid>`
- `PATCH /rest/v1/artisan_profiles?user_id=eq.<auth.uid>`

## Catalogue
- `GET /rest/v1/craft_categories?select=*`
- `GET /rest/v1/products?status=eq.published&select=*,product_media(*),product_stories(*)`
- `POST /rest/v1/products` (artisan-owned draft; RLS enforced)
- `PATCH /rest/v1/products?id=eq.<id>` (owner only)
- Media upload to private `product-media` bucket using user-scoped object paths.
- Product publishing requires server-side validation.

## Agentic listing workflow (Edge Function)
`POST /functions/v1/artbook-agent`
Request:
```json
{
  "action": "start_listing",
  "case_id": null,
  "input": {
    "language": "mr-IN",
    "voice_transcript": "optional transcript",
    "media_paths": ["<private-storage-path>"],
    "artisan_notes": "optional notes"
  }
}
```
Response:
```json
{
  "case_id": "<uuid>",
  "status": "awaiting_artisan_review",
  "step": "listing_draft",
  "draft": {
    "title": "...",
    "description": "...",
    "craft_type": "...",
    "materials": [],
    "technique": "...",
    "origin": null,
    "story": "...",
    "tags": []
  },
  "requires_approval": true
}
```
The service must label AI-inferred fields as suggestions and must not fabricate origin, provenance, materials or artisan credentials.

## Price guidance
`POST /functions/v1/price-guidance`
Input: product attributes, region, quantity and comparable observation filters.
Output: indicative range, currency, observation count, source references, observed_at and confidence.
If sufficient comparable data is unavailable, return `insufficient_data`; never fabricate market values. This is guidance, not a guaranteed price or appraisal.

## Buyer discovery
`POST /functions/v1/buyer-matching`
Input: product_id or buyer brief, delivery region, quantity and relevant filters.
Output: ranked eligible buyer leads with match reasons and confidence. Personal contact details are only returned when the user has permission and required consent.

## Negotiation workflow
- `POST /functions/v1/negotiation-draft`: prepares a proposal using the artisan's explicitly saved floor price and terms.
- `POST /functions/v1/agent-approval`: accepts a single-use approval token bound to user, case, action and payload hash.
- No offer transmission, order acceptance, payment capture, legal commitment or personal-data disclosure before approval.
- All approval decisions are recorded in an immutable audit log.

## Orders
- `GET /rest/v1/orders?select=*,order_events(*)` (RLS restricts to buyer or artisan participant)
- Order creation/state transitions go through Edge Functions to enforce inventory, ownership, idempotency and approval rules.
- Payment provider integration is out of scope until a provider, settlement model and compliance requirements are selected.

## Agent case continuity
- Every agent action is associated with a durable `agent_cases` row.
- Persist current step, input/output references, retry count, last error class, next retry time, and approval state.
- Use idempotency keys for externally visible operations.
- Retry transient failures with bounded exponential backoff; never retry an approval-required action by silently approving it.

## Error envelope
```json
{
  "error": {
    "code": "INSUFFICIENT_COMPARABLE_DATA",
    "message": "There is not enough comparable market data to suggest a price.",
    "retryable": false,
    "request_id": "<uuid>"
  }
}
```

## Security
- Enable RLS for every public table.
- Never expose Supabase secret/service-role keys in the Flutter app.
- Edge Functions validate JWT, ownership, schema, state transitions and approvals.
- Storage policies restrict uploads/downloads to authorized owners and published public assets only.
