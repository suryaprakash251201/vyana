import { ScrollArea } from '@/components/ui/scroll-area'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { Plus, MessageSquare, MoreHorizontal } from 'lucide-react'

interface Conversation {
    id: string
    title: string
    lastMessage: string
    timestamp: Date
}

interface ChatSidebarProps {
    conversations: Conversation[]
    activeId?: string
    onSelect: (id: string) => void
    onNew: () => void
    className?: string
}

export function ChatSidebar({
    conversations,
    activeId,
    onSelect,
    onNew,
    className,
}: ChatSidebarProps) {
    return (
        <div className={cn('w-64 border-r border-border bg-card/50 flex flex-col', className)}>
            <div className="p-3 border-b border-border">
                <Button onClick={onNew} className="w-full justify-start gap-2">
                    <Plus className="h-4 w-4" />
                    New Chat
                </Button>
            </div>

            <ScrollArea className="flex-1">
                <div className="p-2 space-y-1">
                    {conversations.length === 0 ? (
                        <div className="p-4 text-center">
                            <MessageSquare className="h-8 w-8 mx-auto text-muted-foreground mb-2" />
                            <p className="text-sm text-muted-foreground">No conversations yet</p>
                        </div>
                    ) : (
                        conversations.map((conversation) => (
                            <button
                                key={conversation.id}
                                onClick={() => onSelect(conversation.id)}
                                className={cn(
                                    'w-full flex items-start gap-2 p-2.5 rounded-lg text-left transition-colors group',
                                    activeId === conversation.id
                                        ? 'bg-primary/20 text-foreground'
                                        : 'hover:bg-muted/50 text-muted-foreground'
                                )}
                            >
                                <MessageSquare className="h-4 w-4 mt-0.5 shrink-0" />
                                <div className="flex-1 min-w-0">
                                    <p className="text-sm font-medium truncate">
                                        {conversation.title}
                                    </p>
                                    <p className="text-xs truncate opacity-60">
                                        {conversation.lastMessage}
                                    </p>
                                </div>
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="h-6 w-6 opacity-0 group-hover:opacity-100 shrink-0"
                                    onClick={(e) => {
                                        e.stopPropagation()
                                        // Handle more options
                                    }}
                                >
                                    <MoreHorizontal className="h-3 w-3" />
                                </Button>
                            </button>
                        ))
                    )}
                </div>
            </ScrollArea>

            <div className="p-3 border-t border-border">
                <p className="text-xs text-muted-foreground text-center">
                    {conversations.length} conversation{conversations.length !== 1 ? 's' : ''}
                </p>
            </div>
        </div>
    )
}
