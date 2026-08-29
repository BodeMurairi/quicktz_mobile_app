import { useEffect, useRef, useState } from 'react'
import { useLocation } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { MessageCircle, Send, Plus, Paperclip, FileText, Download } from 'lucide-react'
import clsx from 'clsx'
import Header from '../components/layout/Header'
import { Card, CardTitle } from '../components/ui/Card'
import Button from '../components/ui/Button'
import Badge from '../components/ui/Badge'
import EmptyState from '../components/ui/EmptyState'
import Modal from '../components/ui/Modal'
import { useConversations } from '../contexts/ConversationsContext'
import { useAuth } from '../contexts/AuthContext'
import { useToast } from '../contexts/ToastContext'
import { customerApi } from '../api/customers'
import { conversationApi } from '../api/conversations'
import { uploadApi } from '../api/uploads'
import { formatDate, formatTime } from '../utils/format'
import type { ChatMessage } from '../types'

type Attachment = { url: string; name: string; type: string }

function AttachmentChip({ attachment, onDark }: { attachment: Attachment; onDark: boolean }) {
  return (
    <a
      href={attachment.url}
      target="_blank"
      rel="noopener noreferrer"
      className={clsx(
        'flex items-center gap-2 rounded-lg px-2.5 py-2 text-xs mt-1.5 transition',
        onDark ? 'bg-white/15 hover:bg-white/25 text-white' : 'bg-white hover:bg-gray-100 text-dark'
      )}
    >
      <FileText className="w-3.5 h-3.5 shrink-0" />
      <span className="truncate flex-1">{attachment.name}</span>
      <Download className="w-3.5 h-3.5 shrink-0" />
    </a>
  )
}

function ChatThread({
  messages,
  loading,
  onSend,
}: {
  messages: ChatMessage[]
  loading: boolean
  onSend: (text: string, attachment?: Attachment) => Promise<void>
}) {
  const toast = useToast()
  const [draft, setDraft] = useState('')
  const [uploading, setUploading] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages.length])

  function handleSend() {
    if (!draft.trim()) return
    onSend(draft)
    setDraft('')
  }

  async function handleFilesSelected(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? [])
    e.target.value = ''
    if (files.length === 0) return

    setUploading(true)
    try {
      for (const file of files) {
        const { url } = await uploadApi.upload(file, 'attachments')
        await onSend(file.name, { url, name: file.name, type: file.type || 'application/octet-stream' })
      }
    } catch {
      toast.error('Could not upload one or more files.')
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="flex flex-col h-full min-h-0">
      <div className="flex-1 min-h-0 overflow-y-auto space-y-3 px-1 py-2">
        {loading ? (
          <p className="text-sm text-gray-400 text-center py-8">Loading…</p>
        ) : messages.length === 0 ? (
          <p className="text-sm text-gray-400 text-center py-8">No messages yet — say hello 👋</p>
        ) : (
          messages.map(m => {
            const isAgency = m.sender === 'agency'
            return (
              <div key={m.id} className={clsx('flex', isAgency ? 'justify-end' : 'justify-start')}>
                <div
                  className={clsx(
                    'max-w-[75%] rounded-2xl px-4 py-2 text-sm',
                    isAgency ? 'bg-primary text-white rounded-br-sm' : 'bg-gray-100 text-dark rounded-bl-sm'
                  )}
                >
                  {m.text && <p>{m.text}</p>}
                  {m.attachment_url && (
                    <AttachmentChip
                      attachment={{
                        url: m.attachment_url,
                        name: m.attachment_name ?? 'Attachment',
                        type: m.attachment_type ?? '',
                      }}
                      onDark={isAgency}
                    />
                  )}
                  <p className={clsx('text-[10px] mt-1', isAgency ? 'text-white/70' : 'text-gray-400')}>
                    {formatTime(m.created_at)}
                  </p>
                </div>
              </div>
            )
          })
        )}
        <div ref={bottomRef} />
      </div>
      <div className="flex items-center gap-2 pt-3 border-t border-gray-100 mt-2 shrink-0">
        <input
          ref={fileInputRef}
          type="file"
          multiple
          className="hidden"
          onChange={handleFilesSelected}
        />
        <button
          onClick={() => fileInputRef.current?.click()}
          disabled={uploading}
          className="p-2 rounded-xl text-gray-400 hover:text-primary hover:bg-primary/10 transition disabled:opacity-50 shrink-0"
          title="Attach files"
          aria-label="Attach files"
        >
          <Paperclip className="w-4 h-4" />
        </button>
        <input
          type="text"
          value={draft}
          onChange={e => setDraft(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSend()}
          placeholder={uploading ? 'Uploading…' : 'Type a message…'}
          disabled={uploading}
          className="flex-1 text-sm bg-gray-50 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-400 disabled:opacity-60"
        />
        <Button size="sm" onClick={handleSend} disabled={!draft.trim() || uploading} leftIcon={<Send className="w-3.5 h-3.5" />}>
          Send
        </Button>
      </div>
    </div>
  )
}

export default function MessagesPage() {
  const location = useLocation()
  const { agency } = useAuth()
  const toast = useToast()
  const qc = useQueryClient()
  const { conversations, isLoading, getMessages, sendMessage } = useConversations()
  const [activeConversationId, setActiveConversationId] = useState<string | null>(null)
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [messagesLoading, setMessagesLoading] = useState(false)
  const [pickerOpen, setPickerOpen] = useState(false)

  // Arriving from "Message this customer" elsewhere in the app — preselect that thread.
  useEffect(() => {
    const conversationId = (location.state as { conversationId?: string } | null)?.conversationId
    if (conversationId) {
      setActiveConversationId(conversationId)
      return
    }
    setActiveConversationId(prev => prev ?? conversations[0]?.id ?? null)
    // Only react to navigation state changes, not every conversations update.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location.state])

  useEffect(() => {
    setActiveConversationId(prev => prev ?? conversations[0]?.id ?? null)
  }, [conversations])

  const { data: customers = [] } = useQuery({
    queryKey: ['customers', agency?.id],
    queryFn: () => customerApi.listByAgency(agency!.id),
    enabled: !!agency && pickerOpen,
  })
  const messageableCustomers = customers.filter(c => c.user_id)

  async function startConversationWith(userId: string) {
    if (!agency) return
    setPickerOpen(false)
    try {
      const conversation = await conversationApi.startConversation(agency.id, userId)
      qc.invalidateQueries({ queryKey: ['conversations', agency.id] })
      setActiveConversationId(conversation.id)
    } catch {
      toast.error('Could not start a conversation. Please try again.')
    }
  }

  useEffect(() => {
    if (!activeConversationId) {
      setMessages([])
      return
    }
    let cancelled = false
    setMessagesLoading(true)
    getMessages(activeConversationId)
      .then(msgs => { if (!cancelled) setMessages(msgs) })
      .finally(() => { if (!cancelled) setMessagesLoading(false) })
    return () => { cancelled = true }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeConversationId])

  const activeConversation = conversations.find(c => c.id === activeConversationId) ?? null

  const sortedConversations = [...conversations].sort((a, b) =>
    (b.last_message?.created_at ?? b.created_at).localeCompare(a.last_message?.created_at ?? a.created_at)
  )

  async function handleSend(text: string, attachment?: Attachment) {
    if (!activeConversationId) return
    await sendMessage(activeConversationId, text, attachment)
    const refreshed = await getMessages(activeConversationId)
    setMessages(refreshed)
  }

  return (
    <div>
      <Header title="Messages" subtitle="Conversations started by riders from the QuickTZ app" />

      <Card padding={false}>
        <div className="flex h-[calc(100vh-240px)] min-h-[420px]">
          {/* Conversation list */}
          <div className="w-72 shrink-0 border-r border-gray-100 flex flex-col">
            <div className="px-4 py-3 border-b border-gray-100 flex items-center justify-between">
              <CardTitle>Conversations</CardTitle>
              <button
                onClick={() => setPickerOpen(true)}
                className="p-1.5 rounded-lg text-primary hover:bg-primary/10 transition"
                title="Start a new conversation"
                aria-label="Start a new conversation"
              >
                <Plus className="w-4 h-4" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto">
              {isLoading ? (
                <p className="text-sm text-gray-400 text-center py-10 px-4">Loading…</p>
              ) : sortedConversations.length === 0 ? (
                <p className="text-sm text-gray-400 text-center py-10 px-4">
                  No conversations yet. Riders can message your agency from the QuickTZ app.
                </p>
              ) : (
                sortedConversations.map(conv => {
                  const last = conv.last_message
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
                      <div className="flex items-center justify-between gap-2 mt-0.5">
                        <p className="text-xs text-gray-400 truncate">
                          {last ? `${last.sender === 'agency' ? 'You: ' : ''}${last.text}` : 'No messages yet'}
                        </p>
                        {conv.unread_count > 0 && (
                          <Badge label={`${conv.unread_count}`} color="primary" />
                        )}
                      </div>
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
                </div>
                <ChatThread
                  messages={messages}
                  loading={messagesLoading}
                  onSend={handleSend}
                />
              </>
            ) : (
              <EmptyState
                icon={MessageCircle}
                title="No conversation selected"
                description="Choose a conversation on the left."
              />
            )}
          </div>
        </div>
      </Card>

      {/* Start a new conversation */}
      <Modal open={pickerOpen} onClose={() => setPickerOpen(false)} title="Start a new conversation" size="sm">
        <div className="space-y-1 max-h-80 overflow-y-auto">
          {messageableCustomers.length === 0 ? (
            <p className="text-sm text-gray-400 text-center py-6">
              No customers with a QuickTZ account yet — only riders who've booked through the app can be messaged.
            </p>
          ) : (
            messageableCustomers.map(c => (
              <button
                key={c.id}
                onClick={() => startConversationWith(c.user_id!)}
                className="w-full flex items-center gap-3 px-3 py-2 rounded-xl hover:bg-gray-50 transition text-left"
              >
                <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                  <span className="text-xs font-bold text-primary">{c.full_name[0]}</span>
                </div>
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium text-dark truncate">{c.full_name}</p>
                  <p className="text-xs text-gray-400 truncate">{c.email ?? c.phone_number ?? '—'}</p>
                </div>
                {conversations.some(conv => conv.user_id === c.user_id) && (
                  <Badge label="existing" color="secondary" />
                )}
              </button>
            ))
          )}
        </div>
      </Modal>
    </div>
  )
}
