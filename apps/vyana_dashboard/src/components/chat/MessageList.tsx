import { ScrollArea } from '@/components/ui/scroll-area'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { cn } from '@/lib/utils'
import { Bot, User } from 'lucide-react'

interface Message {
    id: string
    role: 'user' | 'assistant'
    content: string
    timestamp: Date
}

interface MessageListProps {
    messages: Message[]
    isLoading?: boolean
}

export function MessageList({ messages, isLoading }: MessageListProps) {
    return (
        <ScrollArea className="flex-1 p-4">
            <div className="space-y-4 max-w-3xl mx-auto">
                {messages.map((message) => (
                    <div
                        key={message.id}
                        className={cn(
                            'flex gap-3 animate-slide-in',
                            message.role === 'user' ? 'flex-row-reverse' : ''
                        )}
                    >
                        <Avatar className="h-8 w-8 shrink-0">
                            {message.role === 'assistant' ? (
                                <>
                                    <AvatarFallback className="bg-primary text-primary-foreground">
                                        <Bot className="h-4 w-4" />
                                    </AvatarFallback>
                                </>
                            ) : (
                                <>
                                    <AvatarFallback className="bg-secondary">
                                        <User className="h-4 w-4" />
                                    </AvatarFallback>
                                </>
                            )}
                        </Avatar>

                        <div
                            className={cn(
                                'flex flex-col max-w-[80%]',
                                message.role === 'user' ? 'items-end' : 'items-start'
                            )}
                        >
                            <div
                                className={cn(
                                    'rounded-2xl px-4 py-2.5',
                                    message.role === 'user'
                                        ? 'bg-primary text-primary-foreground rounded-tr-sm'
                                        : 'bg-muted rounded-tl-sm'
                                )}
                            >
                                <p className="text-sm whitespace-pre-wrap">{message.content}</p>
                            </div>
                            <span className="text-xs text-muted-foreground mt-1 px-1">
                                {message.timestamp.toLocaleTimeString([], {
                                    hour: '2-digit',
                                    minute: '2-digit',
                                })}
                            </span>
                        </div>
                    </div>
                ))}

                {isLoading && (
                    <div className="flex gap-3 animate-slide-in">
                        <Avatar className="h-8 w-8 shrink-0">
                            <AvatarFallback className="bg-primary text-primary-foreground">
                                <Bot className="h-4 w-4" />
                            </AvatarFallback>
                        </Avatar>
                        <div className="bg-muted rounded-2xl rounded-tl-sm px-4 py-3">
                            <div className="flex gap-1">
                                <div className="h-2 w-2 rounded-full bg-muted-foreground animate-bounce" style={{ animationDelay: '0ms' }} />
                                <div className="h-2 w-2 rounded-full bg-muted-foreground animate-bounce" style={{ animationDelay: '150ms' }} />
                                <div className="h-2 w-2 rounded-full bg-muted-foreground animate-bounce" style={{ animationDelay: '300ms' }} />
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </ScrollArea>
    )
}
