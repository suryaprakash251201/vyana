import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'
import { AlertCircle, CheckCircle, Info, AlertTriangle } from 'lucide-react'

interface LogEntry {
    id: string
    level: 'info' | 'warning' | 'error' | 'success'
    message: string
    timestamp: string
}

interface LogViewerProps {
    className?: string
}

const logIcons = {
    info: Info,
    warning: AlertTriangle,
    error: AlertCircle,
    success: CheckCircle,
}

const logColors = {
    info: 'text-blue-400 bg-blue-500/10',
    warning: 'text-amber-400 bg-amber-500/10',
    error: 'text-red-400 bg-red-500/10',
    success: 'text-emerald-400 bg-emerald-500/10',
}

const mockLogs: LogEntry[] = [
    { id: '1', level: 'success', message: 'Server started successfully', timestamp: '10:45:23' },
    { id: '2', level: 'info', message: 'New connection from 192.168.1.1', timestamp: '10:45:25' },
    { id: '3', level: 'info', message: 'Chat request processed', timestamp: '10:46:12' },
    { id: '4', level: 'warning', message: 'High memory usage detected', timestamp: '10:47:01' },
    { id: '5', level: 'info', message: 'Task created via API', timestamp: '10:48:33' },
    { id: '6', level: 'success', message: 'Calendar sync completed', timestamp: '10:49:00' },
    { id: '7', level: 'info', message: 'MCP server connected', timestamp: '10:50:15' },
    { id: '8', level: 'error', message: 'Failed to connect to external API', timestamp: '10:51:22' },
    { id: '9', level: 'info', message: 'Retry attempt 1/3', timestamp: '10:51:25' },
    { id: '10', level: 'success', message: 'Connection restored', timestamp: '10:51:30' },
]

export function LogViewer({ className }: LogViewerProps) {
    return (
        <Card className={cn('glass', className)}>
            <CardHeader className="pb-2">
                <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">Activity Logs</CardTitle>
                    <Badge variant="outline" className="font-mono text-xs">
                        {mockLogs.length} entries
                    </Badge>
                </div>
            </CardHeader>
            <CardContent>
                <ScrollArea className="h-[300px] pr-4">
                    <div className="space-y-2">
                        {mockLogs.map((log) => {
                            const Icon = logIcons[log.level]
                            return (
                                <div
                                    key={log.id}
                                    className={cn(
                                        'flex items-start gap-3 p-2 rounded-lg text-sm',
                                        logColors[log.level]
                                    )}
                                >
                                    <Icon className="h-4 w-4 mt-0.5 shrink-0" />
                                    <div className="flex-1 min-w-0">
                                        <p className="truncate">{log.message}</p>
                                    </div>
                                    <span className="text-xs opacity-60 font-mono shrink-0">
                                        {log.timestamp}
                                    </span>
                                </div>
                            )
                        })}
                    </div>
                </ScrollArea>
            </CardContent>
        </Card>
    )
}
