import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import { Plug, Settings, Trash2 } from 'lucide-react'

interface EndpointCardProps {
    name: string
    url: string
    status: 'connected' | 'disconnected' | 'error'
    tools?: string[]
    lastConnected?: string
    className?: string
    onConnect?: () => void
    onDisconnect?: () => void
    onEdit?: () => void
    onDelete?: () => void
}

const statusConfig = {
    connected: {
        label: 'Connected',
        color: 'bg-emerald-500',
        badge: 'success' as const,
    },
    disconnected: {
        label: 'Disconnected',
        color: 'bg-muted-foreground',
        badge: 'secondary' as const,
    },
    error: {
        label: 'Error',
        color: 'bg-red-500',
        badge: 'destructive' as const,
    },
}

export function EndpointCard({
    name,
    url,
    status,
    tools = [],
    lastConnected,
    className,
    onConnect,
    onDisconnect,
    onEdit,
    onDelete,
}: EndpointCardProps) {
    const config = statusConfig[status]

    return (
        <Card className={cn('glass group', className)}>
            <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                        <div className="h-10 w-10 rounded-lg bg-primary/20 flex items-center justify-center">
                            <Plug className="h-5 w-5 text-primary" />
                        </div>
                        <div>
                            <CardTitle className="text-base">{name}</CardTitle>
                            <p className="text-xs text-muted-foreground font-mono truncate max-w-[200px]">
                                {url}
                            </p>
                        </div>
                    </div>
                    <div className="flex items-center gap-2">
                        <div className={cn('h-2 w-2 rounded-full', config.color)} />
                        <Badge variant={config.badge}>{config.label}</Badge>
                    </div>
                </div>
            </CardHeader>
            <CardContent className="space-y-4">
                {tools.length > 0 && (
                    <div>
                        <p className="text-xs text-muted-foreground mb-2">Available Tools</p>
                        <div className="flex flex-wrap gap-1">
                            {tools.slice(0, 4).map((tool) => (
                                <Badge key={tool} variant="outline" className="text-xs">
                                    {tool}
                                </Badge>
                            ))}
                            {tools.length > 4 && (
                                <Badge variant="outline" className="text-xs">
                                    +{tools.length - 4} more
                                </Badge>
                            )}
                        </div>
                    </div>
                )}

                {lastConnected && (
                    <p className="text-xs text-muted-foreground">
                        Last connected: {lastConnected}
                    </p>
                )}

                <div className="flex items-center gap-2 pt-2">
                    {status === 'connected' ? (
                        <Button
                            variant="outline"
                            size="sm"
                            className="flex-1"
                            onClick={onDisconnect}
                        >
                            Disconnect
                        </Button>
                    ) : (
                        <Button
                            size="sm"
                            className="flex-1"
                            onClick={onConnect}
                        >
                            Connect
                        </Button>
                    )}
                    <Button variant="ghost" size="icon" className="shrink-0" onClick={onEdit}>
                        <Settings className="h-4 w-4" />
                    </Button>
                    <Button
                        variant="ghost"
                        size="icon"
                        className="shrink-0 text-destructive hover:text-destructive"
                        onClick={onDelete}
                    >
                        <Trash2 className="h-4 w-4" />
                    </Button>
                </div>
            </CardContent>
        </Card>
    )
}
