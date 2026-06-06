import clsx from 'clsx'

interface CardProps {
  children: React.ReactNode
  className?: string
  padding?: boolean
  hover?: boolean
}

export function Card({ children, className, padding = true, hover = false }: CardProps) {
  return (
    <div
      className={clsx(
        'bg-white rounded-2xl shadow-card',
        padding && 'p-5',
        hover && 'hover:shadow-lg hover:-translate-y-0.5 transition-all duration-150 cursor-pointer',
        className
      )}
    >
      {children}
    </div>
  )
}

export function CardHeader({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={clsx('flex items-center justify-between mb-4', className)}>
      {children}
    </div>
  )
}

export function CardTitle({ children }: { children: React.ReactNode }) {
  return <h3 className="section-title">{children}</h3>
}
