import { useState, useEffect } from 'react'
import { EndpointCard } from '@/components/connect/EndpointCard'
import { ConnectionForm } from '@/components/connect/ConnectionForm'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Plug, Server, Globe, Zap } from 'lucide-react'

interface Endpoint {
    id: string
    name: string
    url: string
    status: 'connected' | 'disconnected' | 'error'
    tools: string[]
    lastConnected?: string
}

const DEFAULT_ENDPOINTS: Endpoint[] = [
    {
        id: '1',
        name: 'Vyana MCP Server',
        url: 'https://vyana.suryaprakashinfo.in/mcp-server',
        status: 'disconnected',
        tools: ['create_task', 'list_tasks', 'get_calendar', 'send_email'],
        lastConnected: 'Never',
    },
    {
        id: '2',
        name: 'Zerodha Kite MCP',
        url: 'mcp.kite.trade',
        status: 'disconnected',
        tools: ['get_portfolio', 'get_holdings', 'place_order'],
        lastConnected: 'Never',
    },
    {
        id: '3',
        name: 'Local Development',
        url: 'http://localhost:8000/mcp-server',
        status: 'disconnected',
        tools: [],
        lastConnected: 'Never',
    },
]

export function Connect() {
    const [endpoints, setEndpoints] = useState<Endpoint[]>(DEFAULT_ENDPOINTS)
    const [editingEndpoint, setEditingEndpoint] = useState<Endpoint | null>(null)
    const [isDialogOpen, setIsDialogOpen] = useState(false)

    // Load from localStorage on mount
    useEffect(() => {
        const saved = localStorage.getItem('vyana_endpoints')
        if (saved) {
            try {
                setEndpoints(JSON.parse(saved))
            } catch (e) {
                console.error("Failed to parse saved endpoints", e)
            }
        }
    }, [])

    // Save to localStorage on change
    useEffect(() => {
        localStorage.setItem('vyana_endpoints', JSON.stringify(endpoints))
    }, [endpoints])

    const handleAddEndpoint = (data: { name: string; url: string }) => {
        const newEndpoint: Endpoint = {
            id: Date.now().toString(),
            name: data.name,
            url: data.url,
            status: 'disconnected',
            tools: [],
            lastConnected: 'Never',
        }
        setEndpoints([...endpoints, newEndpoint])
    }

    const handleUpdateEndpoint = (data: { name: string; url: string }) => {
        if (!editingEndpoint) return
        setEndpoints(endpoints.map(ep =>
            ep.id === editingEndpoint.id ? { ...ep, ...data } : ep
        ))
        setEditingEndpoint(null)
        setIsDialogOpen(false)
    }

    const handleEdit = (endpoint: Endpoint) => {
        setEditingEndpoint(endpoint)
        setIsDialogOpen(true)
    }

    const handleConnect = async (id: string) => {
        // Optimistic update
        setEndpoints(prev => prev.map(ep =>
            ep.id === id ? { ...ep, status: 'connected', lastConnected: 'Just now' } : ep
        ))

        // Find endpoint to verify
        const endpoint = endpoints.find(ep => ep.id === id)
        if (endpoint) {
            try {
                // Determine if we can actually fetch
                // If it's a websocket (ws://), we can't fetch but can try assuming success for now or implementing WS check
                // For HTTP, try a simple fetch
                if (endpoint.url.startsWith('http')) {
                    await fetch(endpoint.url, { method: 'HEAD', mode: 'no-cors' }) // Verify connectivity roughly
                }
            } catch (e) {
                // Revert if failed
                setEndpoints(prev => prev.map(ep =>
                    ep.id === id ? { ...ep, status: 'error', lastConnected: 'Failed' } : ep
                ))
            }
        }
    }

    const handleDisconnect = (id: string) => {
        setEndpoints(endpoints.map(ep =>
            ep.id === id ? { ...ep, status: 'disconnected' } : ep
        ))
    }

    const handleDelete = (id: string) => {
        setEndpoints(endpoints.filter(ep => ep.id !== id))
    }

    const connectedCount = endpoints.filter(ep => ep.status === 'connected').length

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <div className="flex items-center gap-2 mb-2">
                    <Plug className="h-5 w-5 text-primary" />
                    <Badge variant="secondary">Connect</Badge>
                </div>
                <h1 className="text-2xl font-bold">Endpoint Management</h1>
                <p className="text-muted-foreground">
                    Connect and manage MCP servers and API endpoints
                </p>
            </div>

            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-3">
                <Card className="glass">
                    <CardContent className="p-4">
                        <div className="flex items-center gap-4">
                            <div className="h-10 w-10 rounded-lg bg-emerald-500/20 flex items-center justify-center">
                                <Server className="h-5 w-5 text-emerald-400" />
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Connected</p>
                                <p className="text-xl font-bold">{connectedCount}</p>
                            </div>
                        </div>
                    </CardContent>
                </Card>

                <Card className="glass">
                    <CardContent className="p-4">
                        <div className="flex items-center gap-4">
                            <div className="h-10 w-10 rounded-lg bg-blue-500/20 flex items-center justify-center">
                                <Globe className="h-5 w-5 text-blue-400" />
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Total Endpoints</p>
                                <p className="text-xl font-bold">{endpoints.length}</p>
                            </div>
                        </div>
                    </CardContent>
                </Card>

                <Card className="glass">
                    <CardContent className="p-4">
                        <div className="flex items-center gap-4">
                            <div className="h-10 w-10 rounded-lg bg-amber-500/20 flex items-center justify-center">
                                <Zap className="h-5 w-5 text-amber-400" />
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Available Tools</p>
                                <p className="text-xl font-bold">
                                    {endpoints.reduce((acc, ep) => acc + ep.tools.length, 0)}
                                </p>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Tabs */}
            <Tabs defaultValue="endpoints" className="space-y-4">
                <TabsList>
                    <TabsTrigger value="endpoints">Endpoints</TabsTrigger>
                    <TabsTrigger value="add">Add New</TabsTrigger>
                </TabsList>

                <TabsContent value="endpoints">
                    {endpoints.length === 0 ? (
                        <Card className="glass">
                            <CardContent className="p-12 text-center">
                                <Plug className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                                <h3 className="text-lg font-semibold mb-2">No endpoints configured</h3>
                                <p className="text-muted-foreground mb-4">
                                    Add your first MCP server or API endpoint to get started
                                </p>
                            </CardContent>
                        </Card>
                    ) : (
                        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                            {endpoints.map((endpoint) => (
                                <EndpointCard
                                    key={endpoint.id}
                                    {...endpoint}
                                    onConnect={() => handleConnect(endpoint.id)}
                                    onDisconnect={() => handleDisconnect(endpoint.id)}
                                    onEdit={() => handleEdit(endpoint)}
                                    onDelete={() => handleDelete(endpoint.id)}
                                />
                            ))}
                        </div>
                    )}
                </TabsContent>

                <TabsContent value="add">
                    <div className="grid gap-6 lg:grid-cols-2">
                        <ConnectionForm onSubmit={handleAddEndpoint} />

                        <Card className="glass">
                            <CardHeader className="pb-3">
                                <CardTitle className="text-lg">Quick Connect</CardTitle>
                            </CardHeader>
                            <CardContent className="space-y-3">
                                {[
                                    { name: 'Vyana MCP', url: '/mcp-server', description: 'Built-in MCP server' },
                                    { name: 'Zerodha Kite', url: 'mcp.kite.trade', description: 'Trading & Portfolio' },
                                    { name: 'Local Dev', url: 'http://localhost:8000/mcp-server', description: 'Development server' },
                                ].map((preset) => (
                                    <button
                                        key={preset.name}
                                        onClick={() => handleAddEndpoint({ name: preset.name, url: preset.url })}
                                        className="w-full flex items-center justify-between p-3 rounded-lg bg-muted/30 hover:bg-muted/50 transition-colors text-left"
                                    >
                                        <div>
                                            <p className="font-medium text-sm">{preset.name}</p>
                                            <p className="text-xs text-muted-foreground">{preset.description}</p>
                                        </div>
                                        <Badge variant="outline">Add</Badge>
                                    </button>
                                ))}
                            </CardContent>
                        </Card>
                    </div>
                </TabsContent>
            </Tabs>

            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Edit Endpoint</DialogTitle>
                    </DialogHeader>
                    {editingEndpoint && (
                        <ConnectionForm
                            initialData={editingEndpoint}
                            onSubmit={handleUpdateEndpoint}
                            submitLabel="Save Changes"
                        />
                    )}
                </DialogContent>
            </Dialog>
        </div>
    )
}
