import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import {
  Bus,
  Eye,
  EyeOff,
  AlertCircle,
  CheckCircle2,
  ChevronRight,
  ChevronLeft,
  User,
  Building2,
} from 'lucide-react'
import { useAuth } from '../../contexts/AuthContext'

// ── Step 1 schema ──────────────────────────────────────────────────────────────
const step1Schema = z
  .object({
    full_name: z.string().min(2, 'Name must be at least 2 characters'),
    email: z.string().email('Enter a valid email address'),
    phone_number: z.string().optional(),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    confirm_password: z.string(),
  })
  .refine((d) => d.password === d.confirm_password, {
    message: 'Passwords do not match',
    path: ['confirm_password'],
  })

// ── Step 2 schema ──────────────────────────────────────────────────────────────
const step2Schema = z.object({
  name: z.string().min(2, 'Agency name is required'),
  description: z.string().optional(),
  contact_email: z
    .string()
    .email('Enter a valid email')
    .optional()
    .or(z.literal('')),
  contact_phone: z.string().optional(),
  address: z.string().optional(),
})

type Step1Values = z.infer<typeof step1Schema>
type Step2Values = z.infer<typeof step2Schema>

// ── Progress indicator ─────────────────────────────────────────────────────────
function StepIndicator({ current }: { current: number }) {
  const steps = [
    { n: 1, label: 'Your Account', icon: User },
    { n: 2, label: 'Your Agency', icon: Building2 },
    { n: 3, label: 'Done', icon: CheckCircle2 },
  ]
  return (
    <div className="flex items-center justify-center gap-0 mb-8">
      {steps.map((s, i) => {
        const Icon = s.icon
        const done = current > s.n
        const active = current === s.n
        return (
          <div key={s.n} className="flex items-center">
            <div className="flex flex-col items-center gap-1">
              <div
                className={`w-9 h-9 rounded-full flex items-center justify-center transition-all ${
                  done
                    ? 'bg-green-500 text-white'
                    : active
                    ? 'bg-white text-primary shadow-md'
                    : 'bg-white/20 text-white/50'
                }`}
              >
                {done ? (
                  <CheckCircle2 className="w-5 h-5" />
                ) : (
                  <Icon className="w-4 h-4" />
                )}
              </div>
              <span
                className={`text-xs font-medium whitespace-nowrap ${
                  active ? 'text-white' : done ? 'text-green-300' : 'text-white/40'
                }`}
              >
                {s.label}
              </span>
            </div>
            {i < steps.length - 1 && (
              <div
                className={`w-12 h-0.5 mx-2 mb-5 rounded transition-all ${
                  current > s.n ? 'bg-green-400' : 'bg-white/20'
                }`}
              />
            )}
          </div>
        )
      })}
    </div>
  )
}

// ── Main component ─────────────────────────────────────────────────────────────
export default function RegisterPage() {
  const { register: registerUser } = useAuth()
  const navigate = useNavigate()

  const [step, setStep] = useState(1)
  const [step1Data, setStep1Data] = useState<Step1Values | null>(null)
  const [showPw, setShowPw] = useState(false)
  const [showConfirmPw, setShowConfirmPw] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  // ── Step 1 form ──
  const form1 = useForm<Step1Values>({
    resolver: zodResolver(step1Schema),
    defaultValues: { full_name: '', email: '', phone_number: '', password: '', confirm_password: '' },
  })

  // ── Step 2 form ──
  const form2 = useForm<Step2Values>({
    resolver: zodResolver(step2Schema),
    defaultValues: { name: '', description: '', contact_email: '', contact_phone: '', address: '' },
  })

  function handleStep1(data: Step1Values) {
    setStep1Data(data)
    setStep(2)
  }

  async function handleStep2(data: Step2Values) {
    if (!step1Data) return
    setError('')
    setLoading(true)
    try {
      await registerUser(
        {
          full_name: step1Data.full_name,
          email: step1Data.email,
          phone_number: step1Data.phone_number || undefined,
          password: step1Data.password,
        },
        {
          name: data.name,
          description: data.description || undefined,
          contact_email: data.contact_email || undefined,
          contact_phone: data.contact_phone || undefined,
          address: data.address || undefined,
        },
      )
      setStep(3)
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

        <StepIndicator current={step} />

        {/* ── Step 1: Account ── */}
        {step === 1 && (
          <div className="bg-white rounded-2xl shadow-modal p-8">
            <h2 className="text-xl font-bold text-dark mb-1">Create your account</h2>
            <p className="text-sm text-gray-500 mb-6">You'll use this to log in to the portal</p>

            <form onSubmit={form1.handleSubmit(handleStep1)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">Full name</label>
                <input
                  {...form1.register('full_name')}
                  placeholder="Kofi Mensah"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                />
                {form1.formState.errors.full_name && (
                  <p className="text-xs text-error mt-1">{form1.formState.errors.full_name.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">Email address</label>
                <input
                  {...form1.register('email')}
                  type="email"
                  placeholder="you@agency.com"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                />
                {form1.formState.errors.email && (
                  <p className="text-xs text-error mt-1">{form1.formState.errors.email.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">
                  Phone number <span className="text-gray-400 font-normal">(optional)</span>
                </label>
                <input
                  {...form1.register('phone_number')}
                  type="tel"
                  placeholder="+228 90 00 00 00"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">Password</label>
                <div className="relative">
                  <input
                    {...form1.register('password')}
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
                {form1.formState.errors.password && (
                  <p className="text-xs text-error mt-1">{form1.formState.errors.password.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">Confirm password</label>
                <div className="relative">
                  <input
                    {...form1.register('confirm_password')}
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
                {form1.formState.errors.confirm_password && (
                  <p className="text-xs text-error mt-1">
                    {form1.formState.errors.confirm_password.message}
                  </p>
                )}
              </div>

              <button
                type="submit"
                className="w-full py-3 bg-gradient-to-r from-dark to-primary-500 text-white text-sm font-semibold rounded-xl hover:opacity-90 transition mt-2 flex items-center justify-center gap-2"
              >
                Continue <ChevronRight className="w-4 h-4" />
              </button>
            </form>

            <p className="text-sm text-center text-gray-500 mt-6">
              Already have an account?{' '}
              <Link to="/login" className="text-primary font-medium hover:underline">
                Sign in
              </Link>
            </p>
          </div>
        )}

        {/* ── Step 2: Agency ── */}
        {step === 2 && (
          <div className="bg-white rounded-2xl shadow-modal p-8">
            <h2 className="text-xl font-bold text-dark mb-1">Set up your agency</h2>
            <p className="text-sm text-gray-500 mb-6">This is how passengers and QuickTZ will see you</p>

            {error && (
              <div className="flex items-start gap-2 bg-red-50 text-error text-sm rounded-lg px-4 py-3 mb-5">
                <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={form2.handleSubmit(handleStep2)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">Agency name</label>
                <input
                  {...form2.register('name')}
                  placeholder="e.g. Confort Express"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                />
                {form2.formState.errors.name && (
                  <p className="text-xs text-error mt-1">{form2.formState.errors.name.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-dark mb-1.5">
                  Description <span className="text-gray-400 font-normal">(optional)</span>
                </label>
                <textarea
                  {...form2.register('description')}
                  rows={3}
                  placeholder="Tell passengers what makes your agency great…"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background resize-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-dark mb-1.5">Contact email</label>
                  <input
                    {...form2.register('contact_email')}
                    type="email"
                    placeholder="contact@agency.com"
                    className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                  />
                  {form2.formState.errors.contact_email && (
                    <p className="text-xs text-error mt-1">
                      {form2.formState.errors.contact_email.message}
                    </p>
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-dark mb-1.5">Contact phone</label>
                  <input
                    {...form2.register('contact_phone')}
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
                  {...form2.register('address')}
                  placeholder="Gare routière, Lomé"
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 bg-background"
                />
              </div>

              <div className="flex gap-3 mt-2">
                <button
                  type="button"
                  onClick={() => setStep(1)}
                  className="flex items-center gap-1.5 px-5 py-3 border border-gray-200 text-dark text-sm font-medium rounded-xl hover:bg-gray-50 transition"
                >
                  <ChevronLeft className="w-4 h-4" /> Back
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="flex-1 py-3 bg-gradient-to-r from-dark to-primary-500 text-white text-sm font-semibold rounded-xl hover:opacity-90 transition disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2"
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
                    <>Create Agency <ChevronRight className="w-4 h-4" /></>
                  )}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* ── Step 3: Success ── */}
        {step === 3 && (
          <div className="bg-white rounded-2xl shadow-modal p-8 text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-green-100 mb-5">
              <CheckCircle2 className="w-8 h-8 text-green-500" />
            </div>
            <h2 className="text-xl font-bold text-dark mb-2">You're all set!</h2>
            <p className="text-sm text-gray-500 mb-2">
              Your account and agency have been created successfully.
            </p>
            <p className="text-xs text-gray-400 mb-8">
              Our team will review and verify your agency shortly. You can start setting up routes and schedules in the meantime.
            </p>
            <button
              onClick={() => navigate('/dashboard')}
              className="w-full py-3 bg-gradient-to-r from-dark to-primary-500 text-white text-sm font-semibold rounded-xl hover:opacity-90 transition"
            >
              Go to Dashboard
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
