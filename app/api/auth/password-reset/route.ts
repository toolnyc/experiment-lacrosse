import { getSupabaseService } from "@/lib/supabase/service"
import { getResend } from "@/lib/email/resend-client"
import { NextResponse, type NextRequest } from "next/server"
import { logger, maskEmail } from "@/lib/utils"

const FROM_EMAIL = process.env.RESEND_FROM_EMAIL || 'carter@experimentlacrosse.com'

// Simple in-memory rate limit: max 3 requests per IP per 15-minute window
const rateLimitMap = new Map<string, { count: number; resetAt: number }>()
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000
const RATE_LIMIT_MAX = 3

function isRateLimited(ip: string): boolean {
  const now = Date.now()
  const entry = rateLimitMap.get(ip)

  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(ip, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS })
    return false
  }

  entry.count++
  return entry.count > RATE_LIMIT_MAX
}

export async function POST(request: NextRequest) {
  try {
    const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "unknown"
    if (isRateLimited(ip)) {
      logger.warn("Password reset rate limited", { ip })
      // Return success to avoid leaking info, but don't actually process
      return NextResponse.json({ success: true })
    }

    const { email } = await request.json()

    if (!email) {
      return NextResponse.json({ error: "Email is required" }, { status: 400 })
    }

    const supabase = getSupabaseService()
    const origin = request.nextUrl.origin

    const { data, error } = await supabase.auth.admin.generateLink({
      type: 'recovery',
      email,
      options: {
        redirectTo: `${origin}/auth/callback`,
      },
    })

    if (error) {
      logger.error("Password reset link generation failed", {
        email: maskEmail(email),
        error: error.message,
      })
      // Always return success to avoid leaking whether an email exists
      return NextResponse.json({ success: true })
    }

    // Send the user directly to our auth callback with the hashed token.
    // We bypass Supabase's /auth/v1/verify endpoint entirely because its
    // redirect is broken (Site URL misconfiguration appends our domain as
    // a path segment on the Supabase URL). Our callback uses verifyOtp()
    // to exchange the token_hash for a session server-side.
    const verifyLink = `${origin}/auth/callback?token_hash=${data.properties.hashed_token}&type=recovery`

    const resend = getResend()
    const { error: emailError } = await resend.emails.send({
      from: FROM_EMAIL,
      to: email,
      subject: 'Reset your password — Experiment Lacrosse',
      html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
          <h2>Reset your password</h2>
          <p>We received a request to reset your password. Click the link below to choose a new one:</p>
          <p><a href="${verifyLink}" style="display: inline-block; padding: 12px 24px; background-color: #000; color: #fff; text-decoration: none; border-radius: 6px;">Reset Password</a></p>
          <p style="color: #666; font-size: 14px;">If you didn't request this, you can safely ignore this email.</p>
          <p style="color: #666; font-size: 14px;">This link will expire in 24 hours.</p>
        </div>
      `,
    })

    if (emailError) {
      logger.error("Password reset email send failed", {
        email: maskEmail(email),
        error: emailError.message,
      })
    } else {
      logger.info("Password reset email sent", {
        email: maskEmail(email),
      })
    }

    // Always return success to avoid leaking whether an email exists
    return NextResponse.json({ success: true })
  } catch (err) {
    logger.error("Password reset unexpected error", {
      error: err instanceof Error ? err.message : "Unknown error",
    })
    return NextResponse.json({ error: "An unexpected error occurred" }, { status: 500 })
  }
}
