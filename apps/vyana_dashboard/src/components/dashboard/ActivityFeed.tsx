import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Badge } from '@/components/ui/badge'
import { MessageSquare, Calendar, CheckSquare, Zap } from 'lucide-react'

interface ActivityItem {
    id: string
    type: 'chat' | 'calendar' | 'task' | 'system'
    title: string
    description: string
    time: string
}

const activityIcons = {
    chat: MessageSquare,
    calendar: Calendar,
    task: CheckSquare,
    system: Zap,
}

const activityColors = {
    chat: 'bg-blue-500/20 text-blue-400',
    calendar: 'bg-purple-500/20 text-purple-400',
    task: 'bg-emerald-500/20 text-emerald-400',
    system: 'bg-amber-500/20 text-amber-400',
}

interface ActivityFeedProps {
    activities: ActivityItem[]
}

export function ActivityFeed({ activities }: ActivityFeedProps) {
    return (
        <Card className="glass h-full">
            <CardHeader className="pb-3">
                <CardTitle className="text-lg">Recent Activity</CardTitle>
            </CardHeader>
            <CardContent>
                <ScrollArea className="h-[300px] pr-4">
                    <div className="space-y-4">
                        {activities.map((activity) => {
                            const Icon = activityIcons[activity.type]
                            return (
                                <div
                                    key={activity.id}
                                    className="flex items-start gap-3 animate-slide-in"
                                >
                                    <div
                                        className={`h-8 w-8 rounded-lg ${activityColors[activity.type]} flex items-center justify-center shrink-0`}
                                    >
                                        <Icon className="h-4 w-4" />
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center gap-2">
                                            <p className="text-sm font-medium truncate">
                                                {activity.title}
                                            </p>
                                            <Badge variant="secondary" className="text-xs shrink-0">
                                                {activity.type}
                                            </Badge>
                                        </div>
                                        <p className="text-xs text-muted-foreground truncate">
                                            {activity.description}
                                        </p>
                                        <p className="text-xs text-muted-foreground mt-1">
                                            {activity.time}
                                        </p>
                                    </div>
                                </div>
                            )
                        })}
                    </div>
                </ScrollArea>
            </CardContent>
        </Card>
    )
}
