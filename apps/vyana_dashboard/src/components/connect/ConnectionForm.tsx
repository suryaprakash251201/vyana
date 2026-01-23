import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { cn } from '@/lib/utils'
import { Plus, Loader2 } from 'lucide-react'

interface ConnectionFormProps {
    className?: string
    initialData?: { name: string; url: string }
    onSubmit?: (data: { name: string; url: string }) => void
    submitLabel?: string
}

export function ConnectionForm({ className, initialData, onSubmit, submitLabel = "Add Endpoint" }: ConnectionFormProps) {
    const [name, setName] = useState(initialData?.name || '')
    const [url, setUrl] = useState(initialData?.url || '')
    const [loading, setLoading] = useState(false)

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        if (!name || !url) return

        setLoading(true)
        // Simulate connection attempt
        await new Promise(resolve => setTimeout(resolve, 1500))

        onSubmit?.({ name, url })
        setName('')
        setUrl('')
        setLoading(false)
    }

    return (
        <Card className={cn('glass', className)}>
            <CardHeader className="pb-3">
                <CardTitle className="text-lg flex items-center gap-2">
                    <Plus className="h-5 w-5" />
                    Add New Endpoint
                </CardTitle>
            </CardHeader>
            <CardContent>
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div className="space-y-2">
                        <Label htmlFor="endpoint-name">Endpoint Name</Label>
                        <Input
                            id="endpoint-name"
                            placeholder="My MCP Server"
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            className="bg-background/50"
                        />
                    </div>

                    <div className="space-y-2">
                        <Label htmlFor="endpoint-url">Server URL</Label>
                        <Input
                            id="endpoint-url"
                            placeholder="https://mcp.example.com"
                            value={url}
                            onChange={(e) => setUrl(e.target.value)}
                            className="bg-background/50"
                        />
                        <p className="text-xs text-muted-foreground">
                            Enter the MCP server URL or WebSocket endpoint
                        </p>
                    </div>

                    <Button type="submit" className="w-full" disabled={loading || !name || !url}>
                        {loading ? (
                            <>
                                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                                Connecting...
                            </>
                        ) : (
                            <>
                                <Plus className="h-4 w-4 mr-2" />
                                {submitLabel}
                            </>
                        )}
                    </Button>
                </form>
            </CardContent>
        </Card>
    )
}
