import { useEffect, useRef, useState } from 'react'
import { Users, Star, MessageCircle, Crown, Search, Send, Plus } from 'lucide-react'
import clsx from 'clsx'
import Header from '../../components/layout/Header'
import { Card, CardHeader, CardTitle } from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Badge from '../../components/ui/Badge'
import StatCard from '../../components/ui/StatCard'
import DataTable from '../../components/ui/DataTable'
import EmptyState from '../../components/ui/EmptyState'
import Modal from '../../components/ui/Modal'
import { FormField, Textarea } from '../../components/ui/FormField'
import { mockCustomers, mockReviews, mockConversations } from '../../utils/mockData'
import { formatCurrency, formatDate, formatTime } from '../../utils/format'
import type { Customer, Review, Conversation } from '../../types'

type ActiveTab = 'directory' | 'reviews' | 'messages'

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

// ── Chat thread (shared by the directory quick-chat modal and the inbox) ──────

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

export default function CustomersPage() {
  const [tab, setTab] = useState<ActiveTab>('directory')
  const [search, setSearch] = useState('')
  const [replyTarget, setReplyTarget] = useState<Review | null>(null)
  const [replyText, setReplyText] = useState('')
  const [reviews, setReviews] = useState<Review[]>(mockReviews)

  // ── Messaging state ──────────────────────────────────────────────────────────
  const [conversations, setConversations] = useState<Conversation[]>(mockConversations)
  const [chatCustomer, setChatCustomer] = useState<Customer | null>(null)
  const [activeConversationId, setActiveConversationId] = useState<string | null>(
    mockConversations[0]?.id ?? null
  )
  const [newChatPickerOpen, setNewChatPickerOpen] = useState(false)
  const [typingIds, setTypingIds] = useState<Set<string>>(new Set())

  const filtered = mockCustomers.filter(c =>
    search === '' ||
    c.full_name.toLowerCase().includes(search.toLowerCase()) ||
    c.email?.toLowerCase().includes(search.toLowerCase()) ||
    c.phone_number?.includes(search)
  )

  const avgRating = (reviews.reduce((s, r) => s + r.rating, 0) / reviews.length).toFixed(1)

  function submitReply() {
    if (!replyTarget || !replyText.trim()) return
    setReviews(prev => prev.map(r => r.id === replyTarget.id ? { ...r, reply: replyText } : r))
    setReplyTarget(null)
    setReplyText('')
  }

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

  function openChatWithCustomer(customer: Customer) {
    ensureConversation(customer)
    setChatCustomer(customer)
  }

  function startConversationWith(customer: Customer) {
    const id = ensureConversation(customer)
    setActiveConversationId(id)
    setTab('messages')
    setNewChatPickerOpen(false)
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

  const chatConversation = chatCustomer
    ? conversations.find(c => c.customer_id === chatCustomer.id) ?? null
    : null

  const activeConversation = conversations.find(c => c.id === activeConversationId) ?? null

  const sortedConversations = [...conversations].sort((a, b) => {
    const at = a.messages[a.messages.length - 1]?.created_at ?? ''
    const bt = b.messages[b.messages.length - 1]?.created_at ?? ''
    return bt.localeCompare(at)
  })

  const customersWithoutChat = mockCustomers.filter(
    c => !conversations.some(conv => conv.customer_id === c.id)
  )

  const customerColumns = [
    {
      key: 'full_name',
      header: 'Customer',
      render: (c: Customer) => (
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
            <span className="text-xs font-bold text-primary">{c.full_name[0]}</span>
          </div>
          <div>
            <p className="font-medium text-dark text-sm">{c.full_name}</p>
            <p className="text-xs text-gray-400">{c.email ?? c.phone_number ?? '—'}</p>
          </div>
          {c.is_premium && <Crown className="w-3.5 h-3.5 text-warning" />}
        </div>
      ),
    },
    {
      key: 'booking_count',
      header: 'Total bookings',
      render: (c: Customer) => (
        <span className="font-semibold text-dark">{c.booking_count}</span>
      ),
    },
    {
      key: 'total_spent',
      header: 'Total spent',
      render: (c: Customer) => (
        <span className="font-semibold text-primary">{formatCurrency(c.total_spent)}</span>
      ),
    },
    {
      key: 'last_travel',
      header: 'Last trip',
      render: (c: Customer) => (
        <span className="text-sm text-gray-500">{c.last_travel ? formatDate(c.last_travel) : '—'}</span>
      ),
    },
    {
      key: 'is_premium',
      header: 'Plan',
      render: (c: Customer) => (
        <Badge label={c.is_premium ? 'premium' : 'free'} color={c.is_premium ? 'warning' : 'secondary'} />
      ),
    },
    {
      key: 'actions',
      header: '',
      headerClassName: 'text-right',
      className: 'text-right',
      render: (c: Customer) => (
        <button
          onClick={e => { e.stopPropagation(); openChatWithCustomer(c) }}
          className="inline-flex items-center justify-center w-8 h-8 rounded-lg text-gray-400 hover:text-primary hover:bg-primary/10 transition"
          aria-label={`Message ${c.full_name}`}
          title={`Message ${c.full_name}`}
        >
          <MessageCircle className="w-4 h-4" />
        </button>
      ),
    },
  ]

  return (
    <div>
      <Header title="Customer Relationship" subtitle="Directory, reviews, and messaging" />

      {/* KPIs */}
      <div className="grid grid-cols-4 gap-4 mb-6">
        <StatCard label="Total customers" value={mockCustomers.length} icon={Users} color="primary" />
        <StatCard label="Premium customers" value={mockCustomers.filter(c => c.is_premium).length} icon={Crown} color="warning" />
        <StatCard label="Average rating" value={`${avgRating} / 5`} icon={Star} trend={2.1} color="success" />
        <StatCard label="Pending replies" value={reviews.filter(r => !r.reply).length} icon={MessageCircle} color="error" />
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-4">
        {([
          { key: 'directory', label: `Directory (${mockCustomers.length})` },
          { key: 'reviews', label: `Reviews (${reviews.length})` },
          { key: 'messages', label: 'Messages' },
        ] as { key: ActiveTab; label: string }[]).map(t => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`px-4 py-2 rounded-xl text-sm font-medium transition ${
              tab === t.key ? 'bg-primary text-white shadow-sm' : 'bg-white text-gray-500 shadow-card hover:bg-gray-50'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Directory */}
      {tab === 'directory' && (
        <Card padding={false}>
          <div className="px-5 py-3 border-b border-gray-100 flex items-center gap-3">
            <Search className="w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search by name, email, or phone…"
              className="flex-1 text-sm bg-transparent focus:outline-none"
            />
          </div>
          {filtered.length === 0 ? (
            <EmptyState icon={Users} title="No customers yet" description="Customers who book with your agency will appear here." />
          ) : (
            <DataTable columns={customerColumns} data={filtered} rowKey={c => c.id} />
          )}
        </Card>
      )}

      {/* Reviews */}
      {tab === 'reviews' && (
        <div className="space-y-4">
          {/* Rating summary */}
          <Card>
            <CardHeader>
              <CardTitle>Rating Overview</CardTitle>
              <div className="flex items-baseline gap-2">
                <span className="text-3xl font-extrabold text-dark">{avgRating}</span>
                <span className="text-sm text-gray-400">/ 5.0</span>
              </div>
            </CardHeader>
            <div className="flex gap-1 mb-4">
              {Array.from({ length: 5 }).map((_, i) => (
                <Star key={i} className={`w-5 h-5 ${i < parseFloat(avgRating) ? 'text-warning fill-warning' : 'text-gray-200'}`} />
              ))}
            </div>
            <div className="space-y-2">
              {[5, 4, 3, 2, 1].map(star => {
                const count = reviews.filter(r => r.rating === star).length
                const pct = reviews.length ? Math.round((count / reviews.length) * 100) : 0
                return (
                  <div key={star} className="flex items-center gap-2 text-xs">
                    <span className="w-8 text-gray-500">{star}★</span>
                    <div className="flex-1 h-2 rounded-full bg-gray-100">
                      <div className="h-2 rounded-full bg-warning transition-all" style={{ width: `${pct}%` }} />
                    </div>
                    <span className="w-8 text-right text-gray-400">{count}</span>
                  </div>
                )
              })}
            </div>
          </Card>

          {reviews.map(r => (
            <Card key={r.id}>
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-3">
                  <div className="w-9 h-9 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                    <span className="text-sm font-bold text-primary">{r.customer_name[0]}</span>
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <p className="font-semibold text-dark text-sm">{r.customer_name}</p>
                      <div className="flex">
                        {Array.from({ length: 5 }).map((_, i) => (
                          <Star key={i} className={`w-3 h-3 ${i < r.rating ? 'text-warning fill-warning' : 'text-gray-200'}`} />
                        ))}
                      </div>
                      <span className="text-xs text-gray-400">{r.trip_route}</span>
                    </div>
                    <p className="text-sm text-gray-600 mb-2">{r.comment}</p>

                    {r.reply ? (
                      <div className="ml-4 pl-3 border-l-2 border-primary/30">
                        <p className="text-xs text-gray-400 mb-0.5">Agency reply:</p>
                        <p className="text-sm text-dark">{r.reply}</p>
                      </div>
                    ) : (
                      <Button
                        variant="ghost"
                        size="sm"
                        leftIcon={<MessageCircle className="w-3.5 h-3.5" />}
                        onClick={() => setReplyTarget(r)}
                      >
                        Reply
                      </Button>
                    )}
                  </div>
                </div>
                <span className="text-xs text-gray-400 shrink-0">{formatDate(r.created_at)}</span>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Messages */}
      {tab === 'messages' && (
        <Card padding={false}>
          <div className="flex h-[560px]">
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
      )}

      {/* Quick chat modal, triggered from a customer row in the directory */}
      <Modal
        open={!!chatCustomer}
        onClose={() => setChatCustomer(null)}
        title={chatCustomer ? `Message ${chatCustomer.full_name}` : ''}
        size="lg"
      >
        {chatCustomer && chatConversation && (
          <div className="space-y-3">
            <div className="bg-gray-50 rounded-xl p-3 text-xs text-gray-500 flex flex-wrap gap-x-4 gap-y-1">
              <span><span className="text-gray-400">Customer ID:</span> {chatCustomer.id}</span>
              <span><span className="text-gray-400">Email:</span> {chatCustomer.email ?? '—'}</span>
              <span><span className="text-gray-400">Phone:</span> {chatCustomer.phone_number ?? '—'}</span>
            </div>
            <div className="h-80">
              <ChatThread
                conversation={chatConversation}
                isTyping={typingIds.has(chatConversation.id)}
                onSend={text => sendMessage(chatConversation.id, text)}
              />
            </div>
            <div className="flex justify-end">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setActiveConversationId(chatConversation.id)
                  setTab('messages')
                  setChatCustomer(null)
                }}
              >
                Open in Messages tab →
              </Button>
            </div>
          </div>
        )}
      </Modal>

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

      {/* Reply modal */}
      <Modal open={!!replyTarget} onClose={() => setReplyTarget(null)} title="Reply to review">
        {replyTarget && (
          <div className="space-y-4">
            <div className="bg-gray-50 rounded-xl p-4 text-sm">
              <p className="font-medium text-dark mb-1">{replyTarget.customer_name} — {replyTarget.trip_route}</p>
              <p className="text-gray-600">{replyTarget.comment}</p>
            </div>
            <FormField label="Your response" required>
              <Textarea
                value={replyText}
                onChange={e => setReplyText(e.target.value)}
                rows={4}
                placeholder="Thank you for your feedback…"
              />
            </FormField>
            <div className="flex justify-end gap-3">
              <Button variant="outline" onClick={() => setReplyTarget(null)}>Cancel</Button>
              <Button onClick={submitReply} disabled={!replyText.trim()}>Send reply</Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
