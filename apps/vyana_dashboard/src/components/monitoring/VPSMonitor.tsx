import { useEffect, useState } from 'react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { getSystemStats } from '@/lib/api'
import { Server, HardDrive, Cpu, Activity, RefreshCw } from 'lucide-react'
import { cn } from '@/lib/utils'

interface SystemStats {
    cpu: { percent: number; cores: number[] }
    memory: { total: number; available: number; used: number; percent: number }
    disk: { total: number; used: number; free: number; percent: number }
    network: { bytes_sent: number; bytes_recv: number }
    uptime: string
    platform: string
}

export function VPSMonitor() {
    const [stats, setStats] = useState<SystemStats | null>(null)
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    const fetchStats = async () => {
        setLoading(true)
        try {
            const result = await getSystemStats()
            if (result.error) {
                setError(result.error)
            } else if (result.data) {
                setStats(result.data)
                setError(null)
            }
        } catch (e) {
            setError('Failed to fetch stats')
        }
        setLoading(false)
    }

    useEffect(() => {
        fetchStats()
        const interval = setInterval(fetchStats, 5000)
        return () => clearInterval(interval)
    }, [])

    const formatBytes = (bytes: number) => {
        if (bytes === 0) return '0 B'
        const k = 1024
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
    }

    return (
        <Card className="glass relative overflow-hidden">
            <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-lg flex items-center gap-2">
                    <Server className="h-5 w-5 text-primary" />
                    System Resources ({stats?.platform || 'Unknown'})
                </CardTitle>
                <div className="flex items-center gap-2">
                    {stats?.uptime && (
                        <Badge variant="outline" className="font-mono">
                            Up: {stats.uptime}
                        </Badge>
                    )}
                    <RefreshCw className={cn("h-4 w-4 text-muted-foreground", loading && "animate-spin")} />
                </div>
            </CardHeader>
            <CardContent>
                {error ? (
                    <div className="text-destructive text-sm text-center py-4">{error}</div>
                ) : !stats ? (
                    <div className="text-muted-foreground text-sm text-center py-4">Loading stats...</div>
                ) : (
                    <div className="space-y-6">
                        {/* CPU */}
                        <div className="space-y-2">
                            <div className="flex items-center justify-between text-sm">
                                <span className="flex items-center gap-2">
                                    <Cpu className="h-4 w-4 text-muted-foreground" />
                                    CPU Usage
                                </span>
                                <span className="font-mono font-bold">{stats.cpu.percent}%</span>
                            </div>
                            <div className="h-2 w-full bg-muted rounded-full overflow-hidden">
                                <div
                                    className="h-full bg-primary transition-all duration-500"
                                    style={{ width: `${stats.cpu.percent}%` }}
                                />
                            </div>
                            <div className="grid grid-cols-4 md:grid-cols-8 gap-1 pt-1">
                                {stats.cpu.cores.map((core, i) => (
                                    <div key={i} className="h-8 bg-muted/50 rounded flex items-end overflow-hidden" title={`Core ${i}: ${core}%`}>
                                        <div
                                            className="w-full bg-primary/50"
                                            style={{ height: `${core}%` }}
                                        />
                                    </div>
                                ))}
                            </div>
                        </div>

                        {/* Memory */}
                        <div className="space-y-2">
                            <div className="flex items-center justify-between text-sm">
                                <span className="flex items-center gap-2">
                                    <Activity className="h-4 w-4 text-muted-foreground" />
                                    Memory
                                </span>
                                <span className="font-mono text-xs text-muted-foreground">
                                    {formatBytes(stats.memory.used)} / {formatBytes(stats.memory.total)}
                                </span>
                            </div>
                            <div className="h-2 w-full bg-muted rounded-full overflow-hidden">
                                <div
                                    className="h-full bg-blue-500 transition-all duration-500"
                                    style={{ width: `${stats.memory.percent}%` }}
                                />
                            </div>
                        </div>

                        {/* Disk */}
                        <div className="space-y-2">
                            <div className="flex items-center justify-between text-sm">
                                <span className="flex items-center gap-2">
                                    <HardDrive className="h-4 w-4 text-muted-foreground" />
                                    Disk (Root)
                                </span>
                                <span className="font-mono text-xs text-muted-foreground">
                                    {formatBytes(stats.disk.used)} / {formatBytes(stats.disk.total)}
                                </span>
                            </div>
                            <div className="h-2 w-full bg-muted rounded-full overflow-hidden">
                                <div
                                    className="h-full bg-amber-500 transition-all duration-500"
                                    style={{ width: `${stats.disk.percent}%` }}
                                />
                            </div>
                        </div>
                    </div>
                )}
            </CardContent>
        </Card>
    )
}
