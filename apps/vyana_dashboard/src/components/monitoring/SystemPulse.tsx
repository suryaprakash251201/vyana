import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { cn } from '@/lib/utils'

interface SystemPulseProps {
    className?: string
}

const metrics = [
    { name: 'CPU', value: 23, color: 'bg-blue-500' },
    { name: 'Memory', value: 45, color: 'bg-purple-500' },
    { name: 'Disk', value: 67, color: 'bg-amber-500' },
    { name: 'Network', value: 12, color: 'bg-emerald-500' },
]

export function SystemPulse({ className }: SystemPulseProps) {
    return (
        <Card className={cn('glass', className)}>
            <CardHeader className="pb-2">
                <CardTitle className="text-lg">System Pulse</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
                {metrics.map((metric) => (
                    <div key={metric.name} className="space-y-2">
                        <div className="flex items-center justify-between text-sm">
                            <span className="text-muted-foreground">{metric.name}</span>
                            <span className="font-medium">{metric.value}%</span>
                        </div>
                        <div className="h-2 rounded-full bg-muted overflow-hidden">
                            <div
                                className={cn('h-full rounded-full transition-all duration-500', metric.color)}
                                style={{ width: `${metric.value}%` }}
                            />
                        </div>
                    </div>
                ))}

                <div className="pt-4 grid grid-cols-4 gap-2">
                    {[...Array(12)].map((_, i) => (
                        <div
                            key={i}
                            className="h-8 rounded bg-primary/20 animate-pulse"
                            style={{ animationDelay: `${i * 100}ms` }}
                        />
                    ))}
                </div>
                <p className="text-xs text-center text-muted-foreground">
                    Live system metrics
                </p>
            </CardContent>
        </Card>
    )
}
