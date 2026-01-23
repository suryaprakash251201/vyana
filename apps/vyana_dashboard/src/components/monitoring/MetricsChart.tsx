import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { cn } from '@/lib/utils'
import { TrendingUp } from 'lucide-react'

interface MetricsChartProps {
    className?: string
}

export function MetricsChart({ className }: MetricsChartProps) {
    // Generate mock data points for the chart
    const dataPoints = [35, 45, 30, 55, 40, 60, 45, 70, 55, 65, 50, 75]
    const maxValue = Math.max(...dataPoints)

    return (
        <Card className={cn('glass', className)}>
            <CardHeader className="pb-2">
                <div className="flex items-center justify-between">
                    <CardTitle className="text-lg">API Requests</CardTitle>
                    <div className="flex items-center gap-1 text-emerald-400 text-sm">
                        <TrendingUp className="h-4 w-4" />
                        <span>+24%</span>
                    </div>
                </div>
            </CardHeader>
            <CardContent>
                <div className="h-[200px] flex items-end gap-2">
                    {dataPoints.map((value, index) => (
                        <div
                            key={index}
                            className="flex-1 flex flex-col items-center gap-1"
                        >
                            <div
                                className="w-full rounded-t-md bg-gradient-to-t from-primary to-primary/50 transition-all duration-500 hover:from-primary/80 hover:to-primary/30"
                                style={{
                                    height: `${(value / maxValue) * 100}%`,
                                    animationDelay: `${index * 50}ms`,
                                }}
                            />
                            <span className="text-xs text-muted-foreground">
                                {index + 1}h
                            </span>
                        </div>
                    ))}
                </div>

                <div className="mt-4 grid grid-cols-3 gap-4 text-center">
                    <div>
                        <p className="text-2xl font-bold text-primary">1.2k</p>
                        <p className="text-xs text-muted-foreground">Total Requests</p>
                    </div>
                    <div>
                        <p className="text-2xl font-bold text-emerald-400">98.5%</p>
                        <p className="text-xs text-muted-foreground">Success Rate</p>
                    </div>
                    <div>
                        <p className="text-2xl font-bold text-amber-400">45ms</p>
                        <p className="text-xs text-muted-foreground">Avg Response</p>
                    </div>
                </div>
            </CardContent>
        </Card>
    )
}
