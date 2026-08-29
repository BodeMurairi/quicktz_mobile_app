import { useState } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { Bus, Eye, EyeOff, AlertCircle, CheckCircle2 } from 'lucide-react'
import { agencyAuthApi } from '../../api/agencyAuth'

export default function ResetPasswordPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const prefillEmail = (location.state as { email?: string } | null)?.email ?? ''

  const [email, setEmail] = useState(prefillEmail)
  const [code, setCode] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPw, setShowPw] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    if (password !== confirmPassword) {
      setError('Passwords do not match')
      return
    }
    if (password.length < 8) {
      setError('Password must be at least 8 characters')
      return
    }
    setLoading(true)
    try {
      await agencyAuthApi.resetPassword(email, code, password)
      setDone(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not reset password. Please try again.')
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
          {done ? (
            <div className="text-center">
              <div className="inline-flex items-center justify-center w-14 h-14 rounded-full bg-green-100 mb-4">
                <CheckCircle2 className="w-7 h-7 text-green-500" />
              </div>
              <h2 className="text-xl font-bold text-dark mb-1">Password reset</h2>
              <p className="text-sm text-gray-500 mb-6">You can now sign in with your new password.</p>
              <button
                onClick={() => navigate('/login')}
                className="w-full py-3 bg-gradient-to-r from-dark to-primary-500 text-white text-sm font-semibold rounded-xl hover:opacity-90 transition"
              >
                Sign in
              </button>
            </div>
          ) : (
            <>
              <h2 className="text-xl font-bold text-dark mb-1">Reset your password</h2>
              <p className="text-sm text-gray-500 mb-6">
                Enter the 6-digit code we emailed you and choose a new password.
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

                <div>
                  <label className="block text-sm font-medium text-dark mb-1.5">Reset code</label>
                  <input
                    type="text"
                    inputMode="numeric"
                    value={code}
                    onChange={e => setCode(e.target.value)}
                    placeholder="6-digit code"
                    maxLength={6}
                    required
                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm tracking-widest focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-dark mb-1.5">New password</label>
                  <div className="relative">
                    <input
                      type={showPw ? 'text' : 'password'}
                      value={password}
                      onChange={e => setPassword(e.target.value)}
                      placeholder="At least 8 characters"
                      required
                      className="w-full px-4 py-2.5 pr-10 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPw(v => !v)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                    >
                      {showPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-dark mb-1.5">Confirm new password</label>
                  <input
                    type={showPw ? 'text' : 'password'}
                    value={confirmPassword}
                    onChange={e => setConfirmPassword(e.target.value)}
                    placeholder="Repeat your new password"
                    required
                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3 bg-gradient-to-r from-dark to-primary-500 text-white text-sm font-semibold rounded-xl hover:opacity-90 transition disabled:opacity-60 disabled:cursor-not-allowed mt-2"
                >
                  {loading ? 'Resetting…' : 'Reset password'}
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
