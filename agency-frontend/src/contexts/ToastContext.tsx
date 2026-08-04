import { createContext, useCallback, useContext, useRef, useState } from 'react'
import { CheckCircle2, XCircle, Info, X } from 'lucide-react'
import clsx from 'clsx'

type ToastType = 'success' | 'error' | 'info'

interface Toast {
  id: number
  type: ToastType
  message: string
}

interface ToastContextValue {
  success: (message: string) => void
  error: (message: string) => void
  info: (message: string) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

const ICON: Record<ToastType, React.ComponentType<{ className?: string }>> = {
  success: CheckCircle2,
  error: XCircle,
  info: Info,
}

const STYLE: Record<ToastType, string> = {
  success: 'bg-white border-l-4 border-success text-dark',
  error: 'bg-white border-l-4 border-error text-dark',
  info: 'bg-white border-l-4 border-primary text-dark',
}

const ICON_COLOR: Record<ToastType, string> = {
  success: 'text-success',
  error: 'text-error',
  info: 'text-primary',
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])
  const nextId = useRef(0)

  const dismiss = useCallback((id: number) => {
    setToasts(prev => prev.filter(t => t.id !== id))
  }, [])

  const push = useCallback((type: ToastType, message: string) => {
    const id = nextId.current++
    setToasts(prev => [...prev, { id, type, message }])
    setTimeout(() => dismiss(id), 4000)
  }, [dismiss])

  const value: ToastContextValue = {
    success: message => push('success', message),
    error: message => push('error', message),
    info: message => push('info', message),
  }

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="fixed top-5 right-5 z-[100] flex flex-col gap-2 w-80 max-w-[calc(100vw-2.5rem)]">
        {toasts.map(t => {
          const Icon = ICON[t.type]
          return (
            <div
              key={t.id}
              className={clsx(
                'flex items-start gap-2.5 px-4 py-3 rounded-xl shadow-modal animate-in fade-in slide-in-from-top-2 duration-150',
                STYLE[t.type]
              )}
            >
              <Icon className={clsx('w-4.5 h-4.5 shrink-0 mt-0.5', ICON_COLOR[t.type])} />
              <p className="text-sm flex-1">{t.message}</p>
              <button
                onClick={() => dismiss(t.id)}
                className="text-gray-400 hover:text-gray-600 transition shrink-0"
                aria-label="Dismiss"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          )
        })}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error('useToast must be used within a ToastProvider')
  return ctx
}
