import { apiClient } from './client'
import type { Route, RouteCreate } from '../types'

export const routeApi = {
  listByAgency: async (agencyId: string): Promise<Route[]> => {
    const { data } = await apiClient.get<Route[]>(`/agencies/${agencyId}/routes`)
    return data
  },

  create: async (payload: RouteCreate): Promise<Route> => {
    const { data } = await apiClient.post<Route>('/routes', payload)
    return data
  },

  update: async (id: string, payload: Partial<RouteCreate>): Promise<Route> => {
    const { data } = await apiClient.patch<Route>(`/routes/${id}`, payload)
    return data
  },

  remove: async (id: string): Promise<void> => {
    await apiClient.delete(`/routes/${id}`)
  },
}
