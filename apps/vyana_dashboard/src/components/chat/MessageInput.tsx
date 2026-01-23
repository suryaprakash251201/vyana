import { useState, useRef, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { Send, Mic, Paperclip, Sparkles } from 'lucide-react'

interface MessageInputProps {
    onSend: (message: string) => void
    disabled?: boolean
    className?: string
}

export function MessageInput({ onSend, disabled, className }: MessageInputProps) {
    const [message, setMessage] = useState('')
    const textareaRef = useRef<HTMLTextAreaElement>(null)

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault()
        if (!message.trim() || disabled) return

        onSend(message.trim())
        setMessage('')

        // Reset textarea height
        if (textareaRef.current) {
            textareaRef.current.style.height = 'auto'
        }
    }

    const handleKeyDown = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault()
            handleSubmit(e)
        }
    }

    // Auto-resize textarea
    useEffect(() => {
        if (textareaRef.current) {
            textareaRef.current.style.height = 'auto'
            textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 150)}px`
        }
    }, [message])

    return (
        <form onSubmit={handleSubmit} className={cn('p-4 border-t border-border', className)}>
            <div className="max-w-3xl mx-auto">
                <div className="relative flex items-end gap-2 bg-muted/30 rounded-2xl p-2 border border-border/50 focus-within:border-primary/50 transition-colors">
                    <Button
                        type="button"
                        variant="ghost"
                        size="icon"
                        className="shrink-0 h-9 w-9"
                    >
                        <Paperclip className="h-4 w-4" />
                    </Button>

                    <textarea
                        ref={textareaRef}
                        value={message}
                        onChange={(e) => setMessage(e.target.value)}
                        onKeyDown={handleKeyDown}
                        placeholder="Ask Vyana anything..."
                        disabled={disabled}
                        rows={1}
                        className="flex-1 bg-transparent border-0 resize-none focus:outline-none text-sm placeholder:text-muted-foreground py-2 px-1 max-h-[150px]"
                    />

                    <div className="flex items-center gap-1 shrink-0">
                        <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            className="h-9 w-9"
                        >
                            <Mic className="h-4 w-4" />
                        </Button>

                        <Button
                            type="submit"
                            size="icon"
                            disabled={!message.trim() || disabled}
                            className="h-9 w-9 rounded-xl"
                        >
                            <Send className="h-4 w-4" />
                        </Button>
                    </div>
                </div>

                <div className="flex items-center justify-center gap-2 mt-2">
                    <Sparkles className="h-3 w-3 text-muted-foreground" />
                    <p className="text-xs text-muted-foreground">
                        Powered by Google Gemini • Press Enter to send
                    </p>
                </div>
            </div>
        </form>
    )
}
