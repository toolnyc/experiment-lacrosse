"use client"

import type React from "react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { getSupabaseClient } from "@/lib/supabase/client"
import { useRouter } from "next/navigation"
import { useEffect, useState } from "react"

export default function UpdatePasswordPage() {
  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [loading, setLoading] = useState(false)
  const [checking, setChecking] = useState(true)
  const [error, setError] = useState("")
  const router = useRouter()

  useEffect(() => {
    const supabase = getSupabaseClient()
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (!user) {
        router.replace("/login")
      } else {
        setChecking(false)
      }
    })
  }, [router])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    if (password !== confirmPassword) {
      setError("Passwords do not match")
      return
    }

    if (password.length < 6) {
      setError("Password must be at least 6 characters")
      return
    }

    setLoading(true)

    try {
      const supabase = getSupabaseClient()
      const { error } = await supabase.auth.updateUser({ password })

      if (error) {
        setError(error.message)
      } else {
        router.push("/member/dashboard")
      }
    } catch {
      setError("An unexpected error occurred")
    } finally {
      setLoading(false)
    }
  }

  if (checking) {
    return null
  }

  return (
    <div className="min-h-[70vh] lg:min-h-[77vh] bg-background">
      <div className="py-20 px-4 sm:px-6 lg:px-8">
        <div className="container mx-auto max-w-md">
          <Card>
            <CardHeader className="text-center">
              <CardTitle className="text-2xl">Set new password</CardTitle>
              <CardDescription>Enter your new password below</CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="password">New Password</Label>
                  <Input
                    id="password"
                    type="password"
                    placeholder="Enter new password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="confirmPassword">Confirm Password</Label>
                  <Input
                    id="confirmPassword"
                    type="password"
                    placeholder="Confirm new password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    required
                  />
                </div>
                {error && <p className="text-sm text-destructive">{error}</p>}
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? "Updating..." : "Update Password"}
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
