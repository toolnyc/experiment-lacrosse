## Git workflow 
ALWAYS use git worktrees for feature/fix branches. NEVER commit directly to master unless explicitly told to. Before committing, verify you are on the correct branch with `git branch --show-current`.

## Scope and Focus
When fixing bugs or implementing features, stay tightly scoped to what was asked. Don't expand scope to touch unrelated systems. When the user asks for an explanation, focus on the specific 'why' — not a broad recap of 'what happened'.

## Testing
When writing or expanding tests, prioritize CRITICAL USER FLOWS (purchasing, checkout, auth, payments) over maximizing test count. Quality and coverage of important paths > quantity of trivial tests.

## Architecture Overview
This is a **Next.js 15** application (App Router) for managing lacrosse training sessions. It integrates Supabase for auth/database, Stripe for payments, and Resend for email.

### Key Directories

- `app/` - Next.js App Router pages and API routes
  - `app/api/` - API endpoints (checkout, webhooks, admin operations)
  - `app/admin/` - Admin dashboard (requires @experimentlacrosse.com or @thelacrosselab.com email)
  - `app/member/` - Authenticated user pages
- `components/ui/` - shadcn/ui components (Radix-based, CVA variants)
- `contexts/` - React Context providers (AuthContext, CartContext)
- `lib/` - Shared utilities and service integrations
  - `lib/supabase/` - Supabase client factories (client.ts for browser, server.ts for API routes)
  - `lib/email/` - Resend email service with retry logic
- `emails/` - React Email templates
- `supabase/migrations/` - Database migration files

### State Management

- **AuthContext**: Uses useState for user/session state, integrates with Supabase Auth
- **CartContext**: Uses useReducer for cart operations, persists to browser storage + Supabase

### Supabase Client Pattern

```typescript
// Client components (browser)
import { getSupabaseClient } from '@/lib/supabase/client'
const supabase = getSupabaseClient()

// Server components / API routes
import { getSupabaseServer } from '@/lib/supabase/server'
const supabase = await getSupabaseServer()
```

### Stripe Integration

- Checkout flow starts at `app/api/create-checkout-session/route.ts`
- Webhooks handled at `app/api/webhooks/stripe/route.ts` (signature verification, idempotency)
- Product sync via `lib/stripe-service.ts`
- Waiver signature required before checkout

### Path Alias

`@/*` maps to the project root (e.g., `@/components/ui/button`).

### Date Handling

Use UTC-only helpers from `lib/utils.ts` to prevent timezone issues:
- `parseDateOnlyUTC()`, `formatDateOnly()`, `formatDateRange()`

### Logging

`logger` from `lib/utils.ts` sanitizes sensitive data (emails, tokens, API keys). PII redacted unless `ENABLE_PII_LOGS=true`.
