import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from './contexts/AuthContext'
import { ToastProvider } from './contexts/ToastContext'
import { ConversationsProvider } from './contexts/ConversationsContext'

// Error boundary
import { ErrorBoundary } from './components/ErrorBoundary'

// Layouts
import DashboardLayout from './components/layout/DashboardLayout'

// Auth pages
import LoginPage from './pages/auth/LoginPage'
import RegisterPage from './pages/auth/RegisterPage'
import ForgotPasswordPage from './pages/auth/ForgotPasswordPage'
import ResetPasswordPage from './pages/auth/ResetPasswordPage'

// Feature pages
import DashboardPage from './pages/DashboardPage'
import BookingsPage from './pages/bookings/BookingsPage'
import BookingDetailPage from './pages/bookings/BookingDetailPage'
import ManualBookingPage from './pages/bookings/ManualBookingPage'
import FinancePage from './pages/finance/FinancePage'
import TransactionsPage from './pages/TransactionsPage'
import TripsPage from './pages/schedule/TripsPage'
import RoutesPage from './pages/schedule/RoutesPage'
import CustomersPage from './pages/customers/CustomersPage'
import MessagesPage from './pages/MessagesPage'
import MarketingPage from './pages/marketing/MarketingPage'
import ProfilePage from './pages/ProfilePage'
import SettingsPage from './pages/SettingsPage'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 2, // 2 min
      retry: 1,
    },
  },
})

export default function App() {
  return (
    <ErrorBoundary>
    <QueryClientProvider client={queryClient}>
      <ToastProvider>
      <AuthProvider>
      <ConversationsProvider>
        <BrowserRouter>
          <Routes>
            {/* Public */}
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/reset-password" element={<ResetPasswordPage />} />

            {/* Protected */}
            <Route element={<DashboardLayout />}>
              <Route path="/dashboard" element={<DashboardPage />} />

              {/* Bookings */}
              <Route path="/bookings" element={<BookingsPage />} />
              <Route path="/bookings/manual" element={<ManualBookingPage />} />
              <Route path="/bookings/:id" element={<BookingDetailPage />} />

              {/* Finance */}
              <Route path="/finance" element={<FinancePage />} />
              <Route path="/transactions" element={<TransactionsPage />} />

              {/* Schedule */}
              <Route path="/schedule" element={<TripsPage />} />
              <Route path="/routes" element={<RoutesPage />} />

              {/* Customers */}
              <Route path="/customers" element={<CustomersPage />} />
              <Route path="/customers/reviews" element={<CustomersPage />} />

              {/* Messages */}
              <Route path="/messages" element={<MessagesPage />} />

              {/* Marketing */}
              <Route path="/marketing" element={<MarketingPage />} />

              {/* Profile */}
              <Route path="/profile" element={<ProfilePage />} />

              {/* Settings */}
              <Route path="/settings" element={<SettingsPage />} />
            </Route>

            {/* Default redirect */}
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </ConversationsProvider>
      </AuthProvider>
      </ToastProvider>
    </QueryClientProvider>
    </ErrorBoundary>
  )
}
