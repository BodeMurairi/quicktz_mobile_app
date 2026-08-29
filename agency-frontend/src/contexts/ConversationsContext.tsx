import { createContext, useContext, useEffect, useRef } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { conversationApi } from '../api/conversations'
import { useAuth } from './AuthContext'
import { useToast } from './ToastContext'
import type { Conversation, ChatMessage } from '../types'

// Shared across CustomersPage and MessagesPage, polling the real backend so a
// conversation started from the mobile app shows up here without a manual refresh.

interface ConversationsContextValue {
  conversations: Conversation[]
  isLoading: boolean
  getMessages: (conversationId: string) => Promise<ChatMessage[]>
  sendMessage: (
    conversationId: string,
    text: string,
    attachment?: { url: string; name: string; type: string }
  ) => Promise<void>
}

const ConversationsContext = createContext<ConversationsContextValue | null>(null)

export function ConversationsProvider({ children }: { children: React.ReactNode }) {
  const { agency } = useAuth()
  const toast = useToast()
  const qc = useQueryClient()
  const lastUnreadTotal = useRef<number | null>(null)

  const { data: conversations = [], isLoading } = useQuery({
    queryKey: ['conversations', agency?.id],
    queryFn: () => conversationApi.listByAgency(agency!.id),
    enabled: !!agency,
    refetchInterval: 10_000,
  })

  // Popup a toast whenever total unread messages across all conversations increases —
  // fires app-wide since this provider wraps the whole router, not just the Messages page.
  useEffect(() => {
    if (!agency) return
    const total = conversations.reduce((s, c) => s + c.unread_count, 0)
    if (lastUnreadTotal.current !== null && total > lastUnreadTotal.current) {
      const withNew = [...conversations].sort(
        (a, b) => (b.last_message?.created_at ?? '').localeCompare(a.last_message?.created_at ?? '')
      )[0]
      toast.success(
        withNew ? `New message from ${withNew.customer_name}` : 'You have a new message'
      )
    }
    lastUnreadTotal.current = total
  }, [conversations, agency, toast])

  async function getMessages(conversationId: string): Promise<ChatMessage[]> {
    const messages = await conversationApi.getMessages(agency!.id, conversationId)
    qc.invalidateQueries({ queryKey: ['conversations', agency?.id] })
    return messages
  }

  async function sendMessage(
    conversationId: string,
    text: string,
    attachment?: { url: string; name: string; type: string }
  ) {
    if (!text.trim() && !attachment) return
    await conversationApi.sendMessage(agency!.id, conversationId, text.trim(), attachment)
    qc.invalidateQueries({ queryKey: ['conversations', agency?.id] })
  }

  return (
    <ConversationsContext.Provider value={{ conversations, isLoading, getMessages, sendMessage }}>
      {children}
    </ConversationsContext.Provider>
  )
}

export function useConversations(): ConversationsContextValue {
  const ctx = useContext(ConversationsContext)
  if (!ctx) throw new Error('useConversations must be used within a ConversationsProvider')
  return ctx
}
