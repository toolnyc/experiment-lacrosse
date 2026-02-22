import { getSupabaseServer } from "@/lib/supabase/server"
import { NextResponse, type NextRequest } from "next/server"
import { logger } from "@/lib/utils"

export async function POST(request: NextRequest) {
  try {
    const { email } = await request.json()

    if (!email) {
      return NextResponse.json({ error: "Email is required" }, { status: 400 })
    }

    const supabase = await getSupabaseServer()
    const origin = request.nextUrl.origin

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${origin}/auth/callback`,
    })

    if (error) {
      logger.error("Password reset error", { error: error.message })
    }

    // Always return success to avoid leaking whether an email exists
    return NextResponse.json({ success: true })
  } catch {
    return NextResponse.json({ error: "An unexpected error occurred" }, { status: 500 })
  }
}
