import { apiClient } from './client'
import type { Customer } from '../types'

export const customerApi = {
  listByAgency: async (agencyId: string): Promise<Customer[]> => {
    const { data } = await apiClient.get<Customer[]>(`/agencies/${agencyId}/customers`)
    return data
  },
}
