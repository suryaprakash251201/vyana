import { useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { ScrollArea } from '@/components/ui/scroll-area'
import { cn } from '@/lib/utils'
import { Play, Copy, Check } from 'lucide-react'

interface Endpoint {
    method: 'GET' | 'POST' | 'PUT' | 'DELETE'
    path: string
    description: string
}

const endpoints: Endpoint[] = [
    { method: 'GET', path: '/health', description: 'Check API health status' },
    { method: 'POST', path: '/chat/send', description: 'Send a chat message' },
    { method: 'GET', path: '/tasks/list', description: 'List all tasks' },
    { method: 'POST', path: '/tasks/create', description: 'Create a new task' },
    { method: 'GET', path: '/calendar/today', description: 'Get today\'s events' },
    { method: 'GET', path: '/mcp/servers', description: 'List MCP servers' },
    { method: 'GET', path: '/tools/list', description: 'List available tools' },
]

const methodColors = {
    GET: 'bg-emerald-500/20 text-emerald-400',
    POST: 'bg-blue-500/20 text-blue-400',
    PUT: 'bg-amber-500/20 text-amber-400',
    DELETE: 'bg-red-500/20 text-red-400',
}

interface ApiExplorerProps {
    className?: string
}

export function ApiExplorer({ className }: ApiExplorerProps) {
    const [selectedEndpoint, setSelectedEndpoint] = useState(endpoints[0])
    const [response, setResponse] = useState('')
    const [loading, setLoading] = useState(false)
    const [copied, setCopied] = useState(false)

    const handleTest = async () => {
        setLoading(true)
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 1000))
        setResponse(JSON.stringify({
            status: 'ok',
            data: {
                message: 'API response for ' + selectedEndpoint.path,
                timestamp: new Date().toISOString(),
            }
        }, null, 2))
        setLoading(false)
    }

    const handleCopy = () => {
        navigator.clipboard.writeText(response)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
    }

    return (
        <Card className={cn('glass', className)}>
            <CardHeader className="pb-3">
                <CardTitle className="text-lg">API Explorer</CardTitle>
            </CardHeader>
            <CardContent>
                <Tabs defaultValue="endpoints" className="space-y-4">
                    <TabsList className="grid w-full grid-cols-2">
                        <TabsTrigger value="endpoints">Endpoints</TabsTrigger>
                        <TabsTrigger value="response">Response</TabsTrigger>
                    </TabsList>

                    <TabsContent value="endpoints" className="space-y-4">
                        <ScrollArea className="h-[300px] pr-4">
                            <div className="space-y-2">
                                {endpoints.map((endpoint) => (
                                    <button
                                        key={endpoint.path}
                                        onClick={() => setSelectedEndpoint(endpoint)}
                                        className={cn(
                                            'w-full flex items-center gap-3 p-3 rounded-lg text-left transition-colors',
                                            selectedEndpoint.path === endpoint.path
                                                ? 'bg-primary/20 border border-primary/50'
                                                : 'bg-muted/30 hover:bg-muted/50'
                                        )}
                                    >
                                        <Badge className={cn('font-mono text-xs', methodColors[endpoint.method])}>
                                            {endpoint.method}
                                        </Badge>
                                        <div className="flex-1 min-w-0">
                                            <p className="font-mono text-sm truncate">{endpoint.path}</p>
                                            <p className="text-xs text-muted-foreground truncate">
                                                {endpoint.description}
                                            </p>
                                        </div>
                                    </button>
                                ))}
                            </div>
                        </ScrollArea>

                        <div className="flex gap-2">
                            <Input
                                value={`/api${selectedEndpoint.path}`}
                                readOnly
                                className="font-mono text-sm bg-muted/30"
                            />
                            <Button onClick={handleTest} disabled={loading}>
                                {loading ? (
                                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent" />
                                ) : (
                                    <>
                                        <Play className="h-4 w-4 mr-1" />
                                        Test
                                    </>
                                )}
                            </Button>
                        </div>
                    </TabsContent>

                    <TabsContent value="response">
                        <div className="relative">
                            <ScrollArea className="h-[350px] rounded-lg bg-muted/30 p-4">
                                <pre className="text-sm font-mono whitespace-pre-wrap">
                                    {response || 'No response yet. Click "Test" to try an endpoint.'}
                                </pre>
                            </ScrollArea>
                            {response && (
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="absolute top-2 right-2"
                                    onClick={handleCopy}
                                >
                                    {copied ? (
                                        <Check className="h-4 w-4 text-emerald-400" />
                                    ) : (
                                        <Copy className="h-4 w-4" />
                                    )}
                                </Button>
                            )}
                        </div>
                    </TabsContent>
                </Tabs>
            </CardContent>
        </Card>
    )
}
