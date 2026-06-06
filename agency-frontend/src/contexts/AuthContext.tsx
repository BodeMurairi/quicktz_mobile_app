import React, { createContext, useContext, useState, useEffect, useCallback } from 'react'
import type { AuthUser, Agency, AgencyCreate, RegisterRequest } from '../types'
import { login as loginApi, register as registerApi, getMe } from '../api/auth'
import { agencyApi } from '../api/agencies'

interface AuthContextValue {
  user: AuthUser | null
  agency: Agency | null
  token: string | null
  isLoading: boolean
  login: (identifier: string, password: string) => Promise<void>
  register: (userData: RegisterRequest, agencyData: AgencyCreate) => Promise<void>
  selectAgency: (agency: Agency) => void
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [agency, setAgency] = useState<Agency | null>(null)
  const [token, setToken] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  // Rehydrate from localStorage
  useEffect(() => {
    try {
      const storedToken = localStorage.getItem('agency_token')
      const storedUser  = localStorage.getItem('agency_user')
      const storedAgency = localStorage.getItem('agency_selected')
      if (storedToken && storedUser && storedUser !== 'undefined' && storedUser !== 'null') {
        setToken(storedToken)
        setUser(JSON.parse(storedUser))
        if (storedAgency && storedAgency !== 'undefined' && storedAgency !== 'null') {
          setAgency(JSON.parse(storedAgency))
        }
      } else if (storedUser === 'undefined' || storedAgency === 'undefined') {
        // Clear corrupted values left by a previous bug
        localStorage.removeItem('agency_token')
        localStorage.removeItem('agency_user')
        localStorage.removeItem('agency_selected')
      }
    } catch {
      // Corrupted localStorage — wipe and force re-login
      localStorage.removeItem('agency_token')
      localStorage.removeItem('agency_user')
      localStorage.removeItem('agency_selected')
    } finally {
      setIsLoading(false)
    }
  }, [])

  const login = useCallback(async (identifier: string, password: string) => {
    const res = await loginApi(identifier, password)
    // Persist token first — getMe() and agencyApi.list() need it in the interceptor
    localStorage.setItem('agency_token', res.access_token)
    setToken(res.access_token)

    const user = await getMe()
    setUser(user)
    localStorage.setItem('agency_user', JSON.stringify(user))

    // Auto-select the first agency linked to this account
    try {
      const agencies = await agencyApi.list()
      if (agencies.length > 0) {
        setAgency(agencies[0])
        localStorage.setItem('agency_selected', JSON.stringify(agencies[0]))
      }
    } catch {
      // No agencies yet — user will create one
    }
  }, [])

  const register = useCallback(async (userData: RegisterRequest, agencyData: AgencyCreate) => {
    // 1. Create user account
    const res = await registerApi(userData)
    // Persist token first so subsequent calls are authenticated
    localStorage.setItem('agency_token', res.access_token)
    setToken(res.access_token)

    const user = await getMe()
    setUser(user)
    localStorage.setItem('agency_user', JSON.stringify(user))

    // 2. Create the agency under this account
    const newAgency = await agencyApi.create(agencyData)
    setAgency(newAgency)
    localStorage.setItem('agency_selected', JSON.stringify(newAgency))
  }, [])

  const selectAgency = useCallback((a: Agency) => {
    setAgency(a)
    localStorage.setItem('agency_selected', JSON.stringify(a))
  }, [])

  const logout = useCallback(() => {
    setUser(null)
    setToken(null)
    setAgency(null)
    localStorage.removeItem('agency_token')
    localStorage.removeItem('agency_user')
    localStorage.removeItem('agency_selected')
  }, [])

  return (
    <AuthContext.Provider value={{ user, agency, token, isLoading, login, register, selectAgency, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
