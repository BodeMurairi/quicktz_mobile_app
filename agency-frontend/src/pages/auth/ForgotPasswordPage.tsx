import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Bus, AlertCircle, CheckCircle2 } from 'lucide-react'
import { agencyAuthApi } from '../../api/agencyAuth'

export default function ForgotPasswordPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [sent, setSent] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await agencyAuthApi.forgotPassword(email)
      setSent(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-dark via-primary-700 to-primary-500 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-white/15 backdrop-blur mb-4">
            <Bus className="w-8 h-8 text-white" />
          </div>
          <h1 className="text-3xl font-extrabold text-white tracking-tight">QuickTZ</h1>
          <p className="text-primary-200 mt-1 text-sm">Agency Management Portal</p>
        </div>

        <div className="bg-white rounded-2xl shadow-modal p-8">
          {sent ? (
            <div className="text-center">
              <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-green-100 mb-4">
                <CheckCircle2 className="w-7 h-7 text-green-500" />
              </div>
              <h2 className="text-xl font-bold text-dark mb-1">Check your email</h2>
              <p className="text-sm text-gray-500 mb-6">
                If <span className="font-medium text-dark">{email}</span> is registered, we've sent a 6-digit
                reset code. It expires in 15 minutes.
              </p>
              <button
                onClick={() => navigate('/reset-password', { state: { email } })}
                className="w-full py-3 bg-gradient-to-r from-dark to-primary-500 text-white text-sm font-semibold rounded-xl hover:opacity-90 transition"
              >
                I have my code
              </button>
            </div>
          ) : (
            <>
              <h2 className="text-xl font-bold text-dark mb-1">Forgot your password?</h2>
              <p className="text-sm text-gray-500 mb-6">
                Enter your login email and we'll send you a reset code.
              </p>

              {error && (
                <div className="flex items-start gap-2 bg-red-50 text-error text-sm rounded-lg px-4 py-3 mb-5">
                  <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-dark mb-1.5">Login email</label>
                  <input
                    type="email"
                    value={email}
                    onChange={e => setEmail(e.target.value)}
                    placeholder="you@agency.com"
                    required
                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3 bg-gradient-to-r from-dark to-primary-500 text-white text-sm font-semibold rounded-xl hover:opacity-90 transition disabled:opacity-60 disabled:cursor-not-allowed mt-2"
                >
                  {loading ? 'Sending…' : 'Send reset code'}
                </button>
              </form>
            </>
          )}

          <p className="text-sm text-center text-gray-500 mt-6">
            <Link to="/login" className="text-primary font-medium hover:underline">
              Back to sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
