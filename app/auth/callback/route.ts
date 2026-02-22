import { createServerClient } from "@supabase/ssr"
import { NextResponse, type NextRequest } from "next/server"

export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl
  const code = searchParams.get("code")
  const tokenHash = searchParams.get("token_hash")

  if (!code && !tokenHash) {
    return NextResponse.redirect(`${origin}/login?error=reset_failed`)
  }

  // If we have a token_hash, this is a password reset flow → go to update-password.
  // Otherwise it's an OAuth callback → go to member dashboard.
  const redirectUrl = tokenHash ? `${origin}/update-password` : `${origin}/member/dashboard`
  const response = NextResponse.redirect(redirectUrl)

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet: { name: string; value: string; options?: Record<string, unknown> }[]) {
          cookiesToSet.forEach(({ name, value, options }) => {
            response.cookies.set(name, value, options)
          })
        },
      },
    },
  )

  let error: Error | null = null

  if (tokenHash) {
    // Password reset flow: verify the hashed token directly (bypasses Supabase's
    // broken /auth/v1/verify redirect)
    const result = await supabase.auth.verifyOtp({
      token_hash: tokenHash,
      type: 'recovery',
    })
    error = result.error
  } else if (code) {
    // Standard PKCE flow (e.g. OAuth callbacks)
    const result = await supabase.auth.exchangeCodeForSession(code)
    error = result.error
  }

  if (error) {
    return NextResponse.redirect(`${origin}/login?error=reset_failed`)
  }

  return response
}
