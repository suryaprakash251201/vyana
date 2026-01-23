import { HealthStatus } from '@/components/monitoring/HealthStatus'
import { SystemPulse } from '@/components/monitoring/SystemPulse'
import { LogViewer } from '@/components/monitoring/LogViewer'
import { MetricsChart } from '@/components/monitoring/MetricsChart'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { VPSMonitor } from '@/components/monitoring/VPSMonitor'
import { Activity, Clock, Zap, Globe } from 'lucide-react'

export function Monitoring() {
    const uptime = '5d 12h 34m'
    const activeConnections = 3
    const requestsPerMinute = 42

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <div className="flex items-center gap-2 mb-2">
                    <Activity className="h-5 w-5 text-primary" />
                    <Badge variant="secondary">Monitoring</Badge>
                </div>
                <h1 className="text-2xl font-bold">System Monitoring</h1>
                <p className="text-muted-foreground">
                    Real-time monitoring and health status of your Vyana backend
                </p>
            </div>

            {/* Quick Stats */}
            <div className="grid gap-4 md:grid-cols-3">
                <Card className="glass">
                    <CardContent className="p-4">
                        <div className="flex items-center gap-4">
                            <div className="h-10 w-10 rounded-lg bg-emerald-500/20 flex items-center justify-center">
                                <Clock className="h-5 w-5 text-emerald-400" />
                            </div>
                            <div>
                                <p className="text-sm text-muted-foreground">Uptime</p>
                                <p className="text-xl font-bold">{uptime}</p>
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
                                <p className="text-sm text-muted-foreground">Active Connections</p>
                                <p className="text-xl font-bold">{activeConnections}</p>
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
                                <p className="text-sm text-muted-foreground">Requests/min</p>
                                <p className="text-xl font-bold">{requestsPerMinute}</p>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Main Grid */}
            <div className="grid gap-6 lg:grid-cols-2">
                <HealthStatus />
                <VPSMonitor />
            </div>

            <div className="grid gap-6 lg:grid-cols-2">
                <MetricsChart />
                <LogViewer />
            </div>

            {/* Endpoint Status */}
            <Card className="glass">
                <CardHeader className="pb-2">
                    <CardTitle className="text-lg">Endpoint Status</CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
                        {[
                            { name: '/health', status: 'online', latency: '12ms' },
                            { name: '/chat/send', status: 'online', latency: '45ms' },
                            { name: '/tasks/list', status: 'online', latency: '28ms' },
                            { name: '/calendar/today', status: 'online', latency: '156ms' },
                            { name: '/gmail/unread', status: 'warning', latency: '432ms' },
                            { name: '/mcp/servers', status: 'online', latency: '67ms' },
                            { name: '/voice/transcribe', status: 'online', latency: '234ms' },
                            { name: '/tools/list', status: 'online', latency: '19ms' },
                        ].map((endpoint) => (
                            <div
                                key={endpoint.name}
                                className="flex items-center justify-between p-3 rounded-lg bg-muted/30"
                            >
                                <div className="flex items-center gap-2">
                                    <div
                                        className={`h-2 w-2 rounded-full ${endpoint.status === 'online'
                                            ? 'bg-emerald-500'
                                            : endpoint.status === 'warning'
                                                ? 'bg-amber-500'
                                                : 'bg-red-500'
                                            }`}
                                    />
                                    <span className="text-sm font-mono">{endpoint.name}</span>
                                </div>
                                <span className="text-xs text-muted-foreground">
                                    {endpoint.latency}
                                </span>
                            </div>
                        ))}
                    </div>
                </CardContent>
            </Card>
        </div>
    )
}
