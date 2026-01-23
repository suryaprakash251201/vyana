import { useEffect, useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { getHealth } from '@/lib/api'
import { Server, Wifi, WifiOff, RefreshCw, AlertCircle } from 'lucide-react'
import { cn } from '@/lib/utils'

interface HealthStatusProps {
    className?: string
}

export function HealthStatus({ className }: HealthStatusProps) {
    const [status, setStatus] = useState<'online' | 'offline' | 'checking'>('checking')
    const [version, setVersion] = useState<string>('')
    const [lastCheck, setLastCheck] = useState<Date | null>(null)
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    const checkHealth = async () => {
        setLoading(true)
        setError(null)

        try {
            const result = await Promise.race([
                getHealth(),
                new Promise<{ error: string }>((_, reject) =>
                    setTimeout(() => reject({ error: 'timeout' }), 5000)
                )
            ]).catch(() => ({ error: 'Connection failed' }))

            if ('error' in result) {
                setStatus('offline')
                setError('Backend unreachable')
                setVersion('N/A')
            } else if (result.data) {
                setStatus('online')
                setVersion(result.data.version || '0.1.0')
            } else {
                setStatus('offline')
                setError(result.error || 'Unknown error')
            }
        } catch (e) {
            setStatus('offline')
            setError('Connection timeout')
        }

        setLastCheck(new Date())
        setLoading(false)
    }

    useEffect(() => {
        checkHealth()
        const interval = setInterval(checkHealth, 30000) // Check every 30 seconds
        return () => clearInterval(interval)
    }, [])

    return (
        <Card className={cn('glass', className)}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-lg flex items-center gap-2">
                    <Server className="h-5 w-5" />
                    Backend Health
                </CardTitle>
                <Button
                    variant="ghost"
                    size="icon"
                    onClick={checkHealth}
                    disabled={loading}
                >
                    <RefreshCw className={cn('h-4 w-4', loading && 'animate-spin')} />
                </Button>
            </CardHeader>
            <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">Status</span>
                    <div className="flex items-center gap-2">
                        {status === 'online' ? (
                            <>
                                <Wifi className="h-4 w-4 text-emerald-500" />
                                <Badge variant="success">Online</Badge>
                            </>
                        ) : status === 'offline' ? (
                            <>
                                <WifiOff className="h-4 w-4 text-red-500" />
                                <Badge variant="destructive">Offline</Badge>
                            </>
                        ) : (
                            <>
                                <RefreshCw className="h-4 w-4 animate-spin text-muted-foreground" />
                                <Badge variant="secondary">Checking...</Badge>
                            </>
                        )}
                    </div>
                </div>

                <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">Version</span>
                    <span className="text-sm font-mono">{version || '-'}</span>
                </div>

                <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">Last Check</span>
                    <span className="text-sm">
                        {lastCheck ? lastCheck.toLocaleTimeString() : '-'}
                    </span>
                </div>

                {error && (
                    <div className="flex items-center gap-2 p-2 rounded bg-red-500/10 text-red-400 text-xs">
                        <AlertCircle className="h-3 w-3" />
                        {error}
                    </div>
                )}

                {status === 'online' && (
                    <div className="pt-2">
                        <div className="h-2 w-full rounded-full bg-muted overflow-hidden">
                            <div className="h-full w-full bg-emerald-500 animate-pulse" />
                        </div>
                        <p className="text-xs text-muted-foreground mt-2 text-center">
                            All systems operational
                        </p>
                    </div>
                )}

                {status === 'offline' && (
                    <div className="pt-2">
                        <p className="text-xs text-muted-foreground text-center">
                            Check if the backend server is running
                        </p>
                    </div>
                )}
            </CardContent>
        </Card>
    )
}
