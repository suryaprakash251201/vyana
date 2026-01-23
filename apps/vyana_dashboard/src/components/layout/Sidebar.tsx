import { Link, useLocation } from 'react-router-dom'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Separator } from '@/components/ui/separator'
import {
    LayoutDashboard,
    Activity,
    Compass,
    Plug,
    MessageSquare,
    Settings,
    HelpCircle,
    Zap,
    ChevronLeft,
    ChevronRight,
} from 'lucide-react'
import { useState, useEffect } from 'react'
import { getHealth } from '@/lib/api'

const navigation = [
    { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
    { name: 'Monitoring', href: '/monitoring', icon: Activity },
    { name: 'Explore', href: '/explore', icon: Compass },
    { name: 'Connect', href: '/connect', icon: Plug },
    { name: 'Chat', href: '/chat', icon: MessageSquare },
]

const secondaryNavigation = [
    { name: 'Settings', href: '/settings', icon: Settings },
    { name: 'Help', href: '/help', icon: HelpCircle },
]

export function Sidebar() {
    const location = useLocation()
    const [collapsed, setCollapsed] = useState(false)
    const [isOnline, setIsOnline] = useState(false)

    useEffect(() => {
        const checkHealth = async () => {
            try {
                const res = await getHealth().catch(() => ({ error: 'failed' }))
                if (!res || 'error' in res) {
                    setIsOnline(false)
                } else {
                    setIsOnline(true)
                }
            } catch {
                setIsOnline(false)
            }
        }

        checkHealth()
        const interval = setInterval(checkHealth, 30000)
        return () => clearInterval(interval)
    }, [])

    return (
        <div
            className={cn(
                'relative flex flex-col border-r border-border bg-card/50 backdrop-blur-xl transition-all duration-300',
                collapsed ? 'w-16' : 'w-64'
            )}
        >
            {/* Logo */}
            <div className="flex h-16 items-center gap-3 px-4 border-b border-border">
                <div className="h-9 w-9 rounded-lg gradient-primary flex items-center justify-center shrink-0">
                    <Zap className="h-5 w-5 text-white" />
                </div>
                {!collapsed && (
                    <span className="text-xl font-bold text-gradient">Vyana</span>
                )}
            </div>

            {/* Collapse button */}
            <Button
                variant="ghost"
                size="icon"
                className="absolute -right-3 top-20 z-10 h-6 w-6 rounded-full border bg-background shadow-md"
                onClick={() => setCollapsed(!collapsed)}
            >
                {collapsed ? (
                    <ChevronRight className="h-3 w-3" />
                ) : (
                    <ChevronLeft className="h-3 w-3" />
                )}
            </Button>

            {/* Navigation */}
            <ScrollArea className="flex-1 py-4">
                <nav className="space-y-1 px-2">
                    {navigation.map((item) => {
                        const isActive = location.pathname === item.href
                        return (
                            <Link
                                key={item.name}
                                to={item.href}
                                className={cn(
                                    'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all',
                                    isActive
                                        ? 'bg-primary text-primary-foreground shadow-lg shadow-primary/25'
                                        : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                                )}
                            >
                                <item.icon className={cn('h-5 w-5 shrink-0', isActive && 'animate-pulse')} />
                                {!collapsed && <span>{item.name}</span>}
                            </Link>
                        )
                    })}
                </nav>

                <Separator className="my-4 mx-2" />

                <nav className="space-y-1 px-2">
                    {secondaryNavigation.map((item) => {
                        const isActive = location.pathname === item.href
                        return (
                            <Link
                                key={item.name}
                                to={item.href}
                                className={cn(
                                    'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all',
                                    isActive
                                        ? 'bg-primary text-primary-foreground'
                                        : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                                )}
                            >
                                <item.icon className="h-5 w-5 shrink-0" />
                                {!collapsed && <span>{item.name}</span>}
                            </Link>
                        )
                    })}
                </nav>
            </ScrollArea>

            {/* Status indicator */}
            {!collapsed && (
                <div className="p-4 border-t border-border">
                    <div className={cn(
                        "rounded-lg border p-3 transition-colors",
                        isOnline
                            ? "bg-emerald-500/10 border-emerald-500/20"
                            : "bg-red-500/10 border-red-500/20"
                    )}>
                        <div className="flex items-center gap-2">
                            <div className={cn(
                                "h-2 w-2 rounded-full animate-pulse",
                                isOnline ? "bg-emerald-500" : "bg-red-500"
                            )} />
                            <span className={cn(
                                "text-xs font-medium",
                                isOnline ? "text-emerald-400" : "text-red-400"
                            )}>
                                {isOnline ? "System Online" : "Backend Offline"}
                            </span>
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}
