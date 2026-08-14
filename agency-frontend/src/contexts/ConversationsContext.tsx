import { createContext, useContext, useState } from 'react'
import { mockConversations } from '../utils/mockData'
import type { Conversation, Customer } from '../types'

// Shared across CustomersPage (quick-message entry points) and MessagesPage (the
// full inbox) so a conversation started from either place stays in sync.

const AUTO_REPLIES = [
  'Thanks for the update!',
  'Got it, appreciate the quick response.',
  'Perfect, thank you.',
  'Okay, noted — thanks!',
  'Great, see you then!',
]

function conversationIdFor(customerId: string): string {
  return `conv-${customerId}`
}

interface ConversationsContextValue {
  conversations: Conversation[]
  typingIds: Set<string>
  ensureConversation: (customer: Customer) => string
  sendMessage: (conversationId: string, text: string) => void
}

const ConversationsContext = createContext<ConversationsContextValue | null>(null)

export function ConversationsProvider({ children }: { children: React.ReactNode }) {
  const [conversations, setConversations] = useState<Conversation[]>(mockConversations)
  const [typingIds, setTypingIds] = useState<Set<string>>(new Set())

  // Creates the conversation for this customer if it doesn't exist yet, and returns its id.
  function ensureConversation(customer: Customer): string {
    const id = conversationIdFor(customer.id)
    setConversations(prev =>
      prev.some(c => c.id === id)
        ? prev
        : [
            ...prev,
            {
              id,
              customer_id: customer.id,
              customer_name: customer.full_name,
              customer_email: customer.email,
              customer_phone: customer.phone_number,
              messages: [],
            },
          ]
    )
    return id
  }

  function sendMessage(conversationId: string, text: string) {
    if (!text.trim()) return
    const message = { id: `m-${Date.now()}`, sender: 'agency' as const, text: text.trim(), created_at: new Date().toISOString() }
    setConversations(prev =>
      prev.map(c => (c.id === conversationId ? { ...c, messages: [...c.messages, message] } : c))
    )
    // Simulate the customer replying, so the thread demonstrates two-way messaging.
    setTypingIds(prev => new Set(prev).add(conversationId))
    setTimeout(() => {
      setConversations(prev =>
        prev.map(c =>
          c.id === conversationId
            ? {
                ...c,
                messages: [
                  ...c.messages,
                  {
                    id: `m-${Date.now()}-r`,
                    sender: 'customer',
                    text: AUTO_REPLIES[Math.floor(Math.random() * AUTO_REPLIES.length)],
                    created_at: new Date().toISOString(),
                  },
                ],
              }
            : c
        )
      )
      setTypingIds(prev => {
        const next = new Set(prev)
        next.delete(conversationId)
        return next
      })
    }, 1500)
  }

  return (
    <ConversationsContext.Provider value={{ conversations, typingIds, ensureConversation, sendMessage }}>
      {children}
    </ConversationsContext.Provider>
  )
}

export function useConversations(): ConversationsContextValue {
  const ctx = useContext(ConversationsContext)
  if (!ctx) throw new Error('useConversations must be used within a ConversationsProvider')
  return ctx
}
