import { useState, useRef, useEffect } from 'react'
import { MessageList } from '@/components/chat/MessageList'
import { MessageInput } from '@/components/chat/MessageInput'
import { ChatSidebar } from '@/components/chat/ChatSidebar'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { sendChatMessage } from '@/lib/api'
import { PanelLeftClose, PanelLeft, Bot, AlertCircle } from 'lucide-react'

interface Message {
    id: string
    role: 'user' | 'assistant'
    content: string
    timestamp: Date
}

interface Conversation {
    id: string
    title: string
    lastMessage: string
    timestamp: Date
    messages: Message[]
}

export function Chat() {
    const [sidebarOpen, setSidebarOpen] = useState(true)
    const [conversations, setConversations] = useState<Conversation[]>([
        {
            id: '1',
            title: 'Task Management',
            lastMessage: 'I have created the task for you',
            timestamp: new Date(),
            messages: [
                {
                    id: '1',
                    role: 'user',
                    content: 'What are my tasks for today?',
                    timestamp: new Date(Date.now() - 60000),
                },
                {
                    id: '2',
                    role: 'assistant',
                    content: 'Here are your tasks for today:\n\n1. Review project documentation\n2. Team standup meeting at 10 AM\n3. Complete code review for PR #123\n4. Update weekly report\n\nWould you like me to help you with any of these?',
                    timestamp: new Date(Date.now() - 30000),
                },
            ],
        },
        {
            id: '2',
            title: 'Calendar Query',
            lastMessage: 'You have 3 meetings today',
            timestamp: new Date(Date.now() - 3600000),
            messages: [],
        },
    ])
    const [activeConversationId, setActiveConversationId] = useState<string>('1')
    const [isLoading, setIsLoading] = useState(false)
    const [connectionError, setConnectionError] = useState(false)

    const activeConversation = conversations.find(c => c.id === activeConversationId)

    // Check backend health on mount
    useEffect(() => {
        const checkConnection = async () => {
            try {
                const response = await fetch(`${import.meta.env.VITE_API_URL || 'https://vyana.suryaprakashinfo.in'}/health`)
                if (!response.ok) {
                    setConnectionError(true)
                } else {
                    setConnectionError(false)
                }
            } catch (error) {
                console.error("Health check failed:", error)
                setConnectionError(true)
            }
        }
        checkConnection()
    }, [])

    const handleSendMessage = async (content: string) => {
        if (!activeConversation) return

        const userMessage: Message = {
            id: Date.now().toString(),
            role: 'user',
            content,
            timestamp: new Date(),
        }

        // Add user message immediately
        setConversations(prev => prev.map(c =>
            c.id === activeConversationId
                ? { ...c, messages: [...c.messages, userMessage], lastMessage: content }
                : c
        ))

        setIsLoading(true)
        setConnectionError(false)

        try {
            // Call API with timeout
            const result = await Promise.race([
                sendChatMessage(content, activeConversationId),
                new Promise<never>((_, reject) =>
                    setTimeout(() => reject(new Error('timeout')), 15000)
                )
            ]).catch(() => ({ error: 'Connection timeout', data: undefined }))

            let assistantContent: string

            if (result.error || !result.data?.response) {
                setConnectionError(true)
                // Provide a helpful fallback response
                assistantContent = "I apologize, but I'm currently unable to connect to the backend server. Please check:\n\n1. Is the backend server running?\n2. Is the API URL correctly configured?\n3. Are there any network issues?\n\nYou can try again in a moment, or check the Monitoring page for server status."
            } else {
                assistantContent = result.data.response
            }

            const assistantMessage: Message = {
                id: (Date.now() + 1).toString(),
                role: 'assistant',
                content: assistantContent,
                timestamp: new Date(),
            }

            // Add assistant message
            setConversations(prev => prev.map(c =>
                c.id === activeConversationId
                    ? {
                        ...c,
                        messages: [...c.messages, assistantMessage],
                        lastMessage: assistantContent.substring(0, 50) + '...'
                    }
                    : c
            ))
        } catch (error) {
            setConnectionError(true)
            const errorMessage: Message = {
                id: (Date.now() + 1).toString(),
                role: 'assistant',
                content: 'Connection error. The backend server appears to be offline. Please check the server status and try again.',
                timestamp: new Date(),
            }

            setConversations(prev => prev.map(c =>
                c.id === activeConversationId
                    ? { ...c, messages: [...c.messages, errorMessage] }
                    : c
            ))
        }

        setIsLoading(false)
    }

    const handleNewChat = () => {
        const newConversation: Conversation = {
            id: Date.now().toString(),
            title: 'New Conversation',
            lastMessage: '',
            timestamp: new Date(),
            messages: [],
        }
        setConversations([newConversation, ...conversations])
        setActiveConversationId(newConversation.id)
    }

    return (
        <div className="h-[calc(100vh-7rem)] flex rounded-xl overflow-hidden border border-border bg-card/30">
            {/* Sidebar */}
            {sidebarOpen && (
                <ChatSidebar
                    conversations={conversations}
                    activeId={activeConversationId}
                    onSelect={setActiveConversationId}
                    onNew={handleNewChat}
                />
            )}

            {/* Main Chat Area */}
            <div className="flex-1 flex flex-col">
                {/* Chat Header */}
                <div className="h-14 border-b border-border px-4 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => setSidebarOpen(!sidebarOpen)}
                        >
                            {sidebarOpen ? (
                                <PanelLeftClose className="h-4 w-4" />
                            ) : (
                                <PanelLeft className="h-4 w-4" />
                            )}
                        </Button>
                        <div className="flex items-center gap-2">
                            <div className="h-8 w-8 rounded-lg bg-primary/20 flex items-center justify-center">
                                <Bot className="h-4 w-4 text-primary" />
                            </div>
                            <div>
                                <p className="text-sm font-medium">Vyana AI</p>
                                <p className={connectionError ? "text-xs text-amber-400" : "text-xs text-emerald-400"}>
                                    {connectionError ? 'Connection Issue' : 'Online'}
                                </p>
                            </div>
                        </div>
                    </div>

                    {connectionError && (
                        <Badge variant="warning" className="flex items-center gap-1">
                            <AlertCircle className="h-3 w-3" />
                            Backend Offline
                        </Badge>
                    )}
                </div>

                {/* Messages */}
                {activeConversation && activeConversation.messages.length > 0 ? (
                    <MessageList
                        messages={activeConversation.messages}
                        isLoading={isLoading}
                    />
                ) : (
                    <div className="flex-1 flex items-center justify-center">
                        <div className="text-center max-w-md p-8">
                            <div className="h-16 w-16 rounded-2xl bg-primary/20 flex items-center justify-center mx-auto mb-4">
                                <Bot className="h-8 w-8 text-primary" />
                            </div>
                            <h3 className="text-xl font-semibold mb-2">How can I help you today?</h3>
                            <p className="text-muted-foreground mb-6">
                                I'm your AI executive assistant. I can help you manage tasks,
                                check your calendar, send emails, and much more.
                            </p>
                            <div className="grid gap-2">
                                {[
                                    'What are my tasks for today?',
                                    'Schedule a meeting for tomorrow',
                                    'Check my unread emails',
                                ].map((suggestion) => (
                                    <button
                                        key={suggestion}
                                        onClick={() => handleSendMessage(suggestion)}
                                        className="text-left p-3 rounded-lg bg-muted/30 hover:bg-muted/50 transition-colors text-sm"
                                    >
                                        {suggestion}
                                    </button>
                                ))}
                            </div>
                        </div>
                    </div>
                )}

                {/* Input */}
                <MessageInput onSend={handleSendMessage} disabled={isLoading} />
            </div>
        </div>
    )
}
