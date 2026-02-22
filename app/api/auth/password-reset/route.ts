import { getSupabaseService } from "@/lib/supabase/service"
import { getResend } from "@/lib/email/resend-client"
import { NextResponse, type NextRequest } from "next/server"
import { logger, maskEmail } from "@/lib/utils"

const FROM_EMAIL = process.env.RESEND_FROM_EMAIL || 'carter@experimentlacrosse.com'

export async function POST(request: NextRequest) {
  try {
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

    // Construct the verification URL ourselves instead of using data.properties.action_link.
    // Supabase's action_link has a broken redirect_to (Site URL misconfiguration causes
    // "supabase.co/experiment-lacrosse.vercel.app" instead of a proper redirect).
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
    const redirectTo = encodeURIComponent(`${origin}/auth/callback`)
    const verifyLink = `${supabaseUrl}/auth/v1/verify?token=${data.properties.hashed_token}&type=recovery&redirect_to=${redirectTo}`

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
