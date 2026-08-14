import { useEffect, useRef, useState } from 'react'
import { useLocation } from 'react-router-dom'
import { Plus, MessageCircle, Send } from 'lucide-react'
import clsx from 'clsx'
import Header from '../components/layout/Header'
import { Card, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import Modal from '../components/ui/Modal'
import Badge from '../components/ui/Badge'
import EmptyState from '../components/ui/EmptyState'
import { useConversations } from '../contexts/ConversationsContext'
import { mockCustomers } from '../utils/mockData'
import { formatDate, formatTime } from '../utils/format'
import type { Conversation } from '../types'

function ChatThread({
  conversation,
  isTyping,
  onSend,
}: {
  conversation: Conversation
  isTyping: boolean
  onSend: (text: string) => void
}) {
  const [draft, setDraft] = useState('')
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [conversation.messages.length, isTyping])

  function handleSend() {
    if (!draft.trim()) return
    onSend(draft)
    setDraft('')
  }

  return (
    <div className="flex flex-col h-full min-h-0">
      <div className="flex-1 min-h-0 overflow-y-auto space-y-3 px-1 py-2">
        {conversation.messages.length === 0 ? (
          <p className="text-sm text-gray-400 text-center py-8">No messages yet — say hello 👋</p>
        ) : (
          conversation.messages.map(m => (
            <div key={m.id} className={clsx('flex', m.sender === 'agency' ? 'justify-end' : 'justify-start')}>
              <div
                className={clsx(
                  'max-w-[75%] rounded-2xl px-4 py-2 text-sm',
                  m.sender === 'agency' ? 'bg-primary text-white rounded-br-sm' : 'bg-gray-100 text-dark rounded-bl-sm'
                )}
              >
                <p>{m.text}</p>
                <p className={clsx('text-[10px] mt-1', m.sender === 'agency' ? 'text-white/70' : 'text-gray-400')}>
                  {formatTime(m.created_at)}
                </p>
              </div>
            </div>
          ))
        )}
        {isTyping && (
          <div className="flex justify-start">
            <div className="bg-gray-100 rounded-2xl rounded-bl-sm px-4 py-2 text-sm text-gray-400 italic">
              typing…
            </div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>
      <div className="flex items-center gap-2 pt-3 border-t border-gray-100 mt-2 shrink-0">
        <input
          type="text"
          value={draft}
          onChange={e => setDraft(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSend()}
          placeholder="Type a message…"
          className="flex-1 text-sm bg-gray-50 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-400"
        />
        <Button size="sm" onClick={handleSend} disabled={!draft.trim()} leftIcon={<Send className="w-3.5 h-3.5" />}>
          Send
        </Button>
      </div>
    </div>
  )
}

export default function MessagesPage() {
  const location = useLocation()
  const { conversations, typingIds, ensureConversation, sendMessage } = useConversations()
  const [activeConversationId, setActiveConversationId] = useState<string | null>(null)
  const [newChatPickerOpen, setNewChatPickerOpen] = useState(false)

  // Arriving from "Message this customer" elsewhere in the app — open/create their thread.
  useEffect(() => {
    const customerId = (location.state as { customerId?: string } | null)?.customerId
    if (customerId) {
      const customer = mockCustomers.find(c => c.id === customerId)
      if (customer) {
        setActiveConversationId(ensureConversation(customer))
        return
      }
    }
    setActiveConversationId(prev => prev ?? conversations[0]?.id ?? null)
    // Only react to navigation state changes, not every conversations update.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location.state])

  function startConversationWith(customer: (typeof mockCustomers)[number]) {
    setActiveConversationId(ensureConversation(customer))
    setNewChatPickerOpen(false)
  }

  const activeConversation = conversations.find(c => c.id === activeConversationId) ?? null

  const sortedConversations = [...conversations].sort((a, b) => {
    const at = a.messages[a.messages.length - 1]?.created_at ?? ''
    const bt = b.messages[b.messages.length - 1]?.created_at ?? ''
    return bt.localeCompare(at)
  })

  const customersWithoutChat = mockCustomers.filter(
    c => !conversations.some(conv => conv.customer_id === c.id)
  )

  return (
    <div>
      <Header title="Messages" subtitle="Chat directly with your customers" />

      <Card padding={false}>
        <div className="flex h-[calc(100vh-240px)] min-h-[420px]">
          {/* Conversation list */}
          <div className="w-72 shrink-0 border-r border-gray-100 flex flex-col">
            <div className="px-4 py-3 border-b border-gray-100 flex items-center justify-between">
              <CardTitle>Conversations</CardTitle>
              <button
                onClick={() => setNewChatPickerOpen(true)}
                className="p-1.5 rounded-lg text-primary hover:bg-primary/10 transition"
                title="Start a new conversation"
                aria-label="Start a new conversation"
              >
                <Plus className="w-4 h-4" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto">
              {sortedConversations.length === 0 ? (
                <p className="text-sm text-gray-400 text-center py-10 px-4">
                  No conversations yet. Start one with a customer.
                </p>
              ) : (
                sortedConversations.map(conv => {
                  const last = conv.messages[conv.messages.length - 1]
                  return (
                    <button
                      key={conv.id}
                      onClick={() => setActiveConversationId(conv.id)}
                      className={clsx(
                        'w-full text-left px-4 py-3 border-b border-gray-50 transition',
                        activeConversationId === conv.id ? 'bg-primary/5' : 'hover:bg-gray-50'
                      )}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <p className="font-medium text-dark text-sm truncate">{conv.customer_name}</p>
                        {last && <span className="text-[10px] text-gray-400 shrink-0">{formatDate(last.created_at)}</span>}
                      </div>
                      <p className="text-xs text-gray-400 truncate mt-0.5">
                        {last ? `${last.sender === 'agency' ? 'You: ' : ''}${last.text}` : 'No messages yet'}
                      </p>
                    </button>
                  )
                })
              )}
            </div>
          </div>

          {/* Active thread */}
          <div className="flex-1 flex flex-col p-4 min-h-0">
            {activeConversation ? (
              <>
                <div className="pb-3 mb-1 border-b border-gray-100 shrink-0">
                  <p className="font-semibold text-dark text-sm">{activeConversation.customer_name}</p>
                  <p className="text-xs text-gray-400">
                    ID: {activeConversation.customer_id} · {activeConversation.customer_email ?? activeConversation.customer_phone ?? '—'}
                  </p>
                </div>
                <ChatThread
                  conversation={activeConversation}
                  isTyping={typingIds.has(activeConversation.id)}
                  onSend={text => sendMessage(activeConversation.id, text)}
                />
              </>
            ) : (
              <EmptyState
                icon={MessageCircle}
                title="No conversation selected"
                description="Choose a conversation on the left, or start a new one."
              />
            )}
          </div>
        </div>
      </Card>

      {/* New conversation picker */}
      <Modal open={newChatPickerOpen} onClose={() => setNewChatPickerOpen(false)} title="Start a new conversation" size="sm">
        <div className="space-y-1 max-h-80 overflow-y-auto">
          {mockCustomers.map(c => (
            <button
              key={c.id}
              onClick={() => startConversationWith(c)}
              className="w-full flex items-center gap-3 px-3 py-2 rounded-xl hover:bg-gray-50 transition text-left"
            >
              <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                <span className="text-xs font-bold text-primary">{c.full_name[0]}</span>
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium text-dark truncate">{c.full_name}</p>
                <p className="text-xs text-gray-400 truncate">{c.email ?? c.phone_number ?? '—'}</p>
              </div>
              {!customersWithoutChat.some(cw => cw.id === c.id) && (
                <Badge label="existing" color="secondary" />
              )}
            </button>
          ))}
        </div>
      </Modal>
    </div>
  )
}
