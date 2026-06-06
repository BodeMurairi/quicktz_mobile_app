import clsx from 'clsx'

interface FormFieldProps {
  label: string
  error?: string
  required?: boolean
  children: React.ReactNode
  className?: string
  hint?: string
}

export function FormField({ label, error, required, children, className, hint }: FormFieldProps) {
  return (
    <div className={clsx('flex flex-col gap-1.5', className)}>
      <label className="text-sm font-medium text-dark">
        {label}
        {required && <span className="text-error ml-0.5">*</span>}
      </label>
      {children}
      {hint && !error && <p className="text-xs text-gray-400">{hint}</p>}
      {error && <p className="text-xs text-error">{error}</p>}
    </div>
  )
}

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: boolean
}

export function Input({ error, className, ...props }: InputProps) {
  return (
    <input
      {...props}
      className={clsx(
        'w-full px-3.5 py-2.5 border rounded-xl text-sm focus:outline-none focus:ring-2 bg-background transition',
        error
          ? 'border-error focus:ring-error/30'
          : 'border-gray-200 focus:ring-primary-400 focus:border-primary-400',
        className
      )}
    />
  )
}

interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  error?: boolean
}

export function Select({ error, className, children, ...props }: SelectProps) {
  return (
    <select
      {...props}
      className={clsx(
        'w-full px-3.5 py-2.5 border rounded-xl text-sm focus:outline-none focus:ring-2 bg-background transition appearance-none',
        error
          ? 'border-error focus:ring-error/30'
          : 'border-gray-200 focus:ring-primary-400 focus:border-primary-400',
        className
      )}
    >
      {children}
    </select>
  )
}

interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  error?: boolean
}

export function Textarea({ error, className, ...props }: TextareaProps) {
  return (
    <textarea
      {...props}
      className={clsx(
        'w-full px-3.5 py-2.5 border rounded-xl text-sm focus:outline-none focus:ring-2 bg-background transition resize-none',
        error
          ? 'border-error focus:ring-error/30'
          : 'border-gray-200 focus:ring-primary-400 focus:border-primary-400',
        className
      )}
    />
  )
}
