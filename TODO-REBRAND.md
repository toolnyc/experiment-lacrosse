# Rebrand Launch TODO

Remaining tasks to complete the rebrand from The Lacrosse Lab to Experiment Lacrosse.

## Database Migration (Required)

- [ ] Apply the new migration to update admin email check in database RLS policies
  ```bash
  # Option 1: Using Supabase CLI
  supabase db push

  # Option 2: Run manually in Supabase SQL Editor
  # Copy contents of: supabase/migrations/20260128000000_update_admin_domain_check.sql
  ```
  This updates the `is_admin_user()` function to recognize both `@experimentlacrosse.com` and `@thelacrosselab.com` as admin emails.

## Resend Email Configuration

- [x] Add new domain in Resend Dashboard
  1. Go to Resend Dashboard → Domains → Add Domain
  2. Add `experimentlacrosse.com`
  3. Add the DNS records Resend provides (SPF, DKIM, DMARC)
  4. Wait for verification (usually a few minutes)

- [x] Update environment variable in production
  ```
  RESEND_FROM_EMAIL=noreply@experimentlacrosse.com
  ```

## DNS / Hosting

- [ ] Ensure `experimentlacrosse.com` DNS is configured and pointing to hosting
- [ ] Update Stripe webhook URL if domain is changing
- [ ] Verify SSL certificate is active for new domain

## Environment Variables (Production)

- [ ] `NEXT_PUBLIC_SITE_URL` → `https://experimentlacrosse.com`
- [ ] `RESEND_FROM_EMAIL` → `noreply@experimentlacrosse.com`

## Post-Launch Verification

- [ ] Test admin login with `@experimentlacrosse.com` email
- [ ] Test admin login with `@thelacrosselab.com` email (should still work)
- [ ] Test purchase flow and confirm email arrives from new domain
- [ ] Verify all pages load correctly on new domain

---

## What's Already Done

- [x] Updated admin email checks in all frontend components (7 files)
- [x] Updated admin email checks in all API routes (5 files)
- [x] Created `isAdminEmail()` helper in `lib/utils.ts` supporting both domains
- [x] Created database migration for dual-domain RLS policies
- [x] Updated package.json name to `experiment-lacrosse`
- [x] Updated CLAUDE.md and DEPLOYMENT.md documentation
- [x] Metadata/SEO already uses "Experiment Lacrosse"
- [x] Contact email already set to `carter@experimentlacrosse.com`
- [x] Instagram handle kept as `@lacrosse.lab` (per request)
