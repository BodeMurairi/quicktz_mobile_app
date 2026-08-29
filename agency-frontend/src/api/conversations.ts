import { apiClient } from './client'
import type { Conversation, ChatMessage } from '../types'

export const conversationApi = {
  listByAgency: async (agencyId: string): Promise<Conversation[]> => {
    const { data } = await apiClient.get<Conversation[]>(`/agencies/${agencyId}/conversations`)
    return data
  },

  getMessages: async (agencyId: string, conversationId: string): Promise<ChatMessage[]> => {
    const { data } = await apiClient.get<ChatMessage[]>(
      `/agencies/${agencyId}/conversations/${conversationId}/messages`
    )
    return data
  },

  sendMessage: async (
    agencyId: string,
    conversationId: string,
    text: string,
    attachment?: { url: string; name: string; type: string }
  ): Promise<ChatMessage> => {
    const { data } = await apiClient.post<ChatMessage>(
      `/agencies/${agencyId}/conversations/${conversationId}/messages`,
      {
        text,
        attachment_url: attachment?.url,
        attachment_name: attachment?.name,
        attachment_type: attachment?.type,
      }
    )
    return data
  },

  startConversation: async (agencyId: string, userId: string): Promise<Conversation> => {
    const { data } = await apiClient.post<Conversation>(
      `/agencies/${agencyId}/conversations`,
      { user_id: userId }
    )
    return data
  },
}
