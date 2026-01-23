import { useEffect, useState } from 'react'
import { useAuth } from '@/context/AuthContext'
import { StatsCard } from '@/components/dashboard/StatsCard'
import { ActivityFeed } from '@/components/dashboard/ActivityFeed'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { getHealth, getTasks, getTodayEvents } from '@/lib/api'
import {
    Activity,
    CheckSquare,
    Calendar,
    MessageSquare,
    ArrowRight,
    Zap,
    Server,
    AlertCircle,
} from 'lucide-react'
import { Link } from 'react-router-dom'

export function Dashboard() {
    const { user } = useAuth()
    const [stats, setStats] = useState({
        backendStatus: 'checking' as 'online' | 'offline' | 'checking',
        tasksCount: 0,
        eventsCount: 0,
        messagesCount: 24,
    })
    const [loading, setLoading] = useState(true)
    const [apiError, setApiError] = useState<string | null>(null)

    useEffect(() => {
        async function fetchData() {
            setLoading(true)
            setApiError(null)

            try {
                // Check backend health with timeout
                const healthResult = await Promise.race([
                    getHealth(),
                    new Promise<{ error: string }>((_, reject) =>
                        setTimeout(() => reject({ error: 'Connection timeout' }), 5000)
                    )
                ]).catch(() => ({ error: 'Connection failed' }))

                if ('error' in healthResult) {
                    setStats(prev => ({ ...prev, backendStatus: 'offline' }))
                    setApiError('Backend server is unreachable')
                } else if (healthResult.data) {
                    setStats(prev => ({ ...prev, backendStatus: 'online' }))
                } else {
                    setStats(prev => ({ ...prev, backendStatus: 'offline' }))
                }

                // Try to get tasks
                const tasksResult = await getTasks().catch(() => ({ data: null }))
                const tasksCount = tasksResult.data?.length || 3 // Fallback demo data

                // Try to get events
                const eventsResult = await getTodayEvents().catch(() => ({ data: null }))
                const eventsCount = eventsResult.data?.length || 2 // Fallback demo data

                setStats(prev => ({
                    ...prev,
                    tasksCount,
                    eventsCount,
                }))
            } catch (error) {
                setApiError('Failed to connect to backend')
                setStats(prev => ({ ...prev, backendStatus: 'offline' }))
            }

            setLoading(false)
        }

        fetchData()

        // Refresh every 30 seconds
        const interval = setInterval(fetchData, 30000)
        return () => clearInterval(interval)
    }, [])

    const activities = [
        {
            id: '1',
            type: 'chat' as const,
            title: 'AI Response Generated',
            description: 'Response to "What are my tasks for today?"',
            time: '2 minutes ago',
        },
        {
            id: '2',
            type: 'task' as const,
            title: 'Task Created',
            description: 'Review project documentation',
            time: '15 minutes ago',
        },
        {
            id: '3',
            type: 'calendar' as const,
            title: 'Event Reminder',
            description: 'Team standup meeting in 30 minutes',
            time: '28 minutes ago',
        },
        {
            id: '4',
            type: 'system' as const,
            title: 'System Health Check',
            description: stats.backendStatus === 'online' ? 'All systems operational' : 'Backend connection issue',
            time: '1 hour ago',
        },
        {
            id: '5',
            type: 'chat' as const,
            title: 'Voice Transcription',
            description: 'Audio message transcribed successfully',
            time: '2 hours ago',
        },
    ]

    const userName = user?.user_metadata?.full_name || user?.email?.split('@')[0] || 'User'

    return (
        <div className="space-y-6">
            {/* API Error Banner */}
            {apiError && (
                <Card className="border-amber-500/30 bg-amber-500/5">
                    <CardContent className="p-4 flex items-center gap-3">
                        <AlertCircle className="h-5 w-5 text-amber-400 shrink-0" />
                        <div className="flex-1">
                            <p className="text-sm font-medium text-amber-400">Backend Connection Issue</p>
                            <p className="text-xs text-muted-foreground">
                                {apiError}. Using demo data. Make sure your backend is running.
                            </p>
                        </div>
                        <Button variant="outline" size="sm" onClick={() => window.location.reload()}>
                            Retry
                        </Button>
                    </CardContent>
                </Card>
            )}

            {/* Welcome Banner */}
            <Card className="glass-strong overflow-hidden">
                <div className="relative p-6 md:p-8">
                    <div className="absolute inset-0 bg-gradient-to-r from-primary/20 via-transparent to-purple-500/20" />
                    <div className="relative z-10">
                        <div className="flex items-center gap-2 mb-2">
                            <Zap className="h-5 w-5 text-primary" />
                            <Badge variant="secondary">Dashboard</Badge>
                        </div>
                        <h1 className="text-2xl md:text-3xl font-bold mb-2">
                            Welcome back, <span className="text-gradient">{userName}</span>
                        </h1>
                        <p className="text-muted-foreground max-w-xl">
                            Here's an overview of your Vyana AI assistant. Monitor performance,
                            manage connections, and explore features all from one place.
                        </p>
                    </div>
                </div>
            </Card>

            {/* Stats Grid */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <StatsCard
                    title="Backend Status"
                    value={
                        loading
                            ? 'Checking...'
                            : stats.backendStatus === 'online'
                                ? 'Online'
                                : 'Offline'
                    }
                    description="API server health"
                    icon={Server}
                    className={
                        stats.backendStatus === 'online'
                            ? 'border-emerald-500/20'
                            : stats.backendStatus === 'offline'
                                ? 'border-red-500/20'
                                : ''
                    }
                />
                <StatsCard
                    title="Active Tasks"
                    value={stats.tasksCount}
                    description="Pending tasks"
                    icon={CheckSquare}
                    trend={{ value: 12, isPositive: true }}
                />
                <StatsCard
                    title="Today's Events"
                    value={stats.eventsCount}
                    description="Calendar events"
                    icon={Calendar}
                />
                <StatsCard
                    title="Messages"
                    value={stats.messagesCount}
                    description="Last 24 hours"
                    icon={MessageSquare}
                    trend={{ value: 8, isPositive: true }}
                />
            </div>

            {/* Main Content Grid */}
            <div className="grid gap-6 lg:grid-cols-3">
                {/* Activity Feed */}
                <div className="lg:col-span-2">
                    <ActivityFeed activities={activities} />
                </div>

                {/* Quick Actions */}
                <Card className="glass">
                    <CardHeader className="pb-3">
                        <CardTitle className="text-lg">Quick Actions</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-3">
                        <Link to="/chat">
                            <Button className="w-full justify-between group" variant="outline">
                                <div className="flex items-center gap-2">
                                    <MessageSquare className="h-4 w-4 text-primary" />
                                    Start a Conversation
                                </div>
                                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                            </Button>
                        </Link>
                        <Link to="/monitoring">
                            <Button className="w-full justify-between group" variant="outline">
                                <div className="flex items-center gap-2">
                                    <Activity className="h-4 w-4 text-emerald-400" />
                                    View Monitoring
                                </div>
                                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                            </Button>
                        </Link>
                        <Link to="/explore">
                            <Button className="w-full justify-between group" variant="outline">
                                <div className="flex items-center gap-2">
                                    <Zap className="h-4 w-4 text-amber-400" />
                                    Explore Features
                                </div>
                                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                            </Button>
                        </Link>
                        <Link to="/connect">
                            <Button className="w-full justify-between group" variant="outline">
                                <div className="flex items-center gap-2">
                                    <Server className="h-4 w-4 text-purple-400" />
                                    Manage Endpoints
                                </div>
                                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                            </Button>
                        </Link>
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}
