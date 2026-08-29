import axios from 'axios'

export const BASE_URL = import.meta.env.VITE_API_URL ?? '/api/v1'

export const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
})

// Attach JWT token to every request
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('agency_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// On a 401, try once to refresh the access token (using the refresh token from
// login/register) and replay the request — otherwise sessions hard-expire the
// moment the 60-minute access token runs out. Uses a plain axios call (not
// apiClient) for the refresh itself so a failed refresh can't recurse back
// into this same interceptor.
let refreshPromise: Promise<string | null> | null = null

async function refreshAccessToken(): Promise<string | null> {
  const refreshToken = localStorage.getItem('agency_refresh_token')
  if (!refreshToken) return null
  try {
    const { data } = await axios.post(`${BASE_URL}/agency-auth/refresh`, { refresh_token: refreshToken })
    localStorage.setItem('agency_token', data.access_token)
    localStorage.setItem('agency_refresh_token', data.refresh_token)
    return data.access_token as string
  } catch {
    return null
  }
}

apiClient.interceptors.response.use(
  (res) => res,
  async (err) => {
    const original = err.config
    if (err.response?.status === 401 && original && !original._retry && localStorage.getItem('agency_refresh_token')) {
      original._retry = true
      refreshPromise = refreshPromise ?? refreshAccessToken()
      const newToken = await refreshPromise
      refreshPromise = null
      if (newToken) {
        original.headers.Authorization = `Bearer ${newToken}`
        return apiClient(original)
      }
      localStorage.removeItem('agency_token')
      localStorage.removeItem('agency_refresh_token')
      localStorage.removeItem('agency_profile')
      window.location.href = '/login'
    }

    const message =
      err.response?.data?.detail ?? err.message ?? 'An unexpected error occurred'
    return Promise.reject(new Error(message))
  }
)
