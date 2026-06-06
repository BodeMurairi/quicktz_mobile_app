import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from './contexts/AuthContext'

// Error boundary
import { ErrorBoundary } from './components/ErrorBoundary'

// Layouts
import DashboardLayout from './components/layout/DashboardLayout'

// Auth pages
import LoginPage from './pages/auth/LoginPage'
import AgencySelectPage from './pages/auth/AgencySelectPage'
import RegisterPage from './pages/auth/RegisterPage'

// Feature pages
import DashboardPage from './pages/DashboardPage'
import BookingsPage from './pages/bookings/BookingsPage'
import BookingDetailPage from './pages/bookings/BookingDetailPage'
import ManualBookingPage from './pages/bookings/ManualBookingPage'
import FinancePage from './pages/finance/FinancePage'
import SchedulePage from './pages/schedule/SchedulePage'
import CustomersPage from './pages/customers/CustomersPage'
import MarketingPage from './pages/marketing/MarketingPage'
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
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            {/* Public */}
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/select-agency" element={<AgencySelectPage />} />

            {/* Protected */}
            <Route element={<DashboardLayout />}>
              <Route path="/dashboard" element={<DashboardPage />} />

              {/* Bookings */}
              <Route path="/bookings" element={<BookingsPage />} />
              <Route path="/bookings/manual" element={<ManualBookingPage />} />
              <Route path="/bookings/:id" element={<BookingDetailPage />} />

              {/* Finance */}
              <Route path="/finance" element={<FinancePage />} />

              {/* Schedule */}
              <Route path="/schedule" element={<SchedulePage />} />

              {/* Customers */}
              <Route path="/customers" element={<CustomersPage />} />
              <Route path="/customers/reviews" element={<CustomersPage />} />

              {/* Marketing */}
              <Route path="/marketing" element={<MarketingPage />} />

              {/* Settings */}
              <Route path="/settings" element={<SettingsPage />} />
            </Route>

            {/* Default redirect */}
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
    </ErrorBoundary>
  )
}
