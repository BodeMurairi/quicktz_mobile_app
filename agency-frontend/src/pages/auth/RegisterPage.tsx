import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Bus, Eye, EyeOff, AlertCircle, ChevronRight } from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'

const registerSchema = z
  .object({
    name: z.string().min(2, 'Agency name is required'),
    login_email: z.string().email('Enter a valid email address'),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    confirm_password: z.string(),
    description: z.string().optional(),
    contact_email: z.string().email('Enter a valid email').optional().or(z.literal('')),
    contact_phone: z.string().optional(),
    address: z.string().optional(),
  })
  .refine((d) => d.password === d.confirm_password, {
    message: 'Passwords do not match',
    path: ['confirm_password'],
  })

type RegisterValues = z.infer<typeof registerSchema>

export default function RegisterPage() {
  const { register: registerAgency } = useAuth()
  const navigate = useNavigate()

  const [showPw, setShowPw] = useState(false)
  const [showConfirmPw, setShowConfirmPw] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const form = useForm<RegisterValues>({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      name: '', login_email: '', password: '', confirm_password: '',
      description: '', contact_email: '', contact_phone: '', address: '',
    },
  })

  async function handleSubmit(data: RegisterValues) {
    setError('')
    setLoading(true)
    try {
      await registerAgency({
        name: data.name,
        login_email: data.login_email,
        password: data.password,
        description: data.description || undefined,
        contact_email: data.contact_email || undefined,
        contact_phone: data.contact_phone || undefined,
        address: data.address || undefined,
      })
      navigate('/dashboard')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Registration failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-dark via-primary-700 to-primary-500 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-white/15 backdrop-blur mb-3">
            <Bus className="w-7 h-7 text-white" />
          </div>
          <h1 className="text-2xl font-extrabold text-white tracking-tight">QuickTZ</h1>
          <p className="text-primary-200 mt-0.5 text-sm">Agency Management Portal</p>
        </div>

        <div className="bg-white rounded-2xl shadow-modal p-8">
          <h2 className="text-xl font-bold text-dark mb-1">Register your agency</h2>
          <p className="text-sm text-gray-500 mb-6">This is how passengers and QuickTZ will see you</p>

          {error && (
            <div className="flex items-start gap-2 bg-red-50 text-error text-sm rounded-lg px-4 py-3 mb-5">
              <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-dark mb-1.5">Agency name</label>
              <input
                {...form.register('name')}
                placeholder="e.g. Confort Express"
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
              />
              {form.formState.errors.name && (
                <p className="text-xs text-error mt-1">{form.formState.errors.name.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-dark mb-1.5">Login email</label>
              <input
                {...form.register('login_email')}
                type="email"
                placeholder="you@agency.com"
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
              />
              {form.formState.errors.login_email && (
                <p className="text-xs text-error mt-1">{form.formState.errors.login_email.message}</p>
              )}
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">Password</label>
                <div className="relative">
                  <input
                    {...form.register('password')}
                    type={showPw ? 'text' : 'password'}
                    placeholder="At least 8 characters"
                    className="w-full px-4 py-2.5 pr-10 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPw((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    {showPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
                {form.formState.errors.password && (
                  <p className="text-xs text-error mt-1">{form.formState.errors.password.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">Confirm password</label>
                <div className="relative">
                  <input
                    {...form.register('confirm_password')}
                    type={showConfirmPw ? 'text' : 'password'}
                    placeholder="Repeat your password"
                    className="w-full px-4 py-2.5 pr-10 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPw((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    {showConfirmPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
                {form.formState.errors.confirm_password && (
                  <p className="text-xs text-error mt-1">
                    {form.formState.errors.confirm_password.message}
                  </p>
                )}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-dark mb-1.5">
                Description <span className="text-gray-400 font-normal">(optional)</span>
              </label>
              <textarea
                {...form.register('description')}
                rows={3}
                placeholder="Tell passengers what makes your agency great…"
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background resize-none"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">
                  Contact email <span className="text-gray-400 font-normal">(optional)</span>
                </label>
                <input
                  {...form.register('contact_email')}
                  type="email"
                  placeholder="contact@agency.com"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                />
                {form.formState.errors.contact_email && (
                  <p className="text-xs text-error mt-1">
                    {form.formState.errors.contact_email.message}
                  </p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">
                  Contact phone <span className="text-gray-400 font-normal">(optional)</span>
                </label>
                <input
                  {...form.register('contact_phone')}
                  type="tel"
                  placeholder="+228 22 00 00 00"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-dark mb-1.5">
                Address <span className="text-gray-400 font-normal">(optional)</span>
              </label>
              <input
                {...form.register('address')}
                placeholder="Gare routière, Lomé"
                className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-gradient-to-r from-dark to-primary-500 text-white text-sm font-semibold rounded-xl hover:opacity-90 transition disabled:opacity-60 disabled:cursor-not-allowed mt-2 flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none">
                    <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="3" strokeOpacity=".25" />
                    <path d="M12 2a10 10 0 0 1 10 10" stroke="currentColor" strokeWidth="3" strokeLinecap="round" />
                  </svg>
                  Creating account…
                </>
              ) : (
                <>Create Agency Account <ChevronRight className="w-4 h-4" /></>
              )}
            </button>
          </form>

          <p className="text-sm text-center text-gray-500 mt-6">
            Already have an account?{' '}
            <Link to="/login" className="text-primary font-medium hover:underline">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
