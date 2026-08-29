import React, { createContext, useContext, useState, useEffect, useCallback } from 'react'
import type { Agency, AgencyRegisterRequest } from '../types'
import { agencyAuthApi } from '../api/agencyAuth'

interface AuthContextValue {
  agency: Agency | null
  token: string | null
  isLoading: boolean
  login: (loginEmail: string, password: string) => Promise<void>
  register: (data: AgencyRegisterRequest) => Promise<void>
  logout: () => void
  updateAgency: (agency: Agency) => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [agency, setAgency] = useState<Agency | null>(null)
  const [token, setToken] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  // Rehydrate from localStorage
  useEffect(() => {
    try {
      const storedToken = localStorage.getItem('agency_token')
      const storedAgency = localStorage.getItem('agency_profile')
      if (storedToken && storedAgency && storedAgency !== 'undefined' && storedAgency !== 'null') {
        setToken(storedToken)
        setAgency(JSON.parse(storedAgency))
      } else {
        localStorage.removeItem('agency_token')
        localStorage.removeItem('agency_refresh_token')
        localStorage.removeItem('agency_profile')
      }
    } catch {
      // Corrupted localStorage — wipe and force re-login
      localStorage.removeItem('agency_token')
      localStorage.removeItem('agency_refresh_token')
      localStorage.removeItem('agency_profile')
    } finally {
      setIsLoading(false)
    }
  }, [])

  const login = useCallback(async (loginEmail: string, password: string) => {
    const res = await agencyAuthApi.login({ login_email: loginEmail, password })
    localStorage.setItem('agency_token', res.access_token)
    localStorage.setItem('agency_refresh_token', res.refresh_token)
    setToken(res.access_token)

    const me = await agencyAuthApi.me()
    setAgency(me)
    localStorage.setItem('agency_profile', JSON.stringify(me))
  }, [])

  const register = useCallback(async (data: AgencyRegisterRequest) => {
    const res = await agencyAuthApi.register(data)
    localStorage.setItem('agency_token', res.access_token)
    localStorage.setItem('agency_refresh_token', res.refresh_token)
    setToken(res.access_token)

    const me = await agencyAuthApi.me()
    setAgency(me)
    localStorage.setItem('agency_profile', JSON.stringify(me))
  }, [])

  const logout = useCallback(() => {
    setAgency(null)
    setToken(null)
    localStorage.removeItem('agency_token')
    localStorage.removeItem('agency_refresh_token')
    localStorage.removeItem('agency_profile')
  }, [])

  const updateAgency = useCallback((updated: Agency) => {
    setAgency(updated)
    localStorage.setItem('agency_profile', JSON.stringify(updated))
  }, [])

  return (
    <AuthContext.Provider value={{ agency, token, isLoading, login, register, logout, updateAgency }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}
