import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'
import type { LucideIcon } from 'lucide-react'
import { ArrowRight } from 'lucide-react'

interface ToolCardProps {
    name: string
    description: string
    icon: LucideIcon
    category: string
    isEnabled?: boolean
    className?: string
}

export function ToolCard({
    name,
    description,
    icon: Icon,
    category,
    isEnabled = true,
    className,
}: ToolCardProps) {
    return (
        <Card className={cn('glass group hover:border-primary/50 transition-all', className)}>
            <CardHeader className="pb-3">
                <div className="flex items-start justify-between">
                    <div className="h-10 w-10 rounded-lg bg-primary/20 flex items-center justify-center">
                        <Icon className="h-5 w-5 text-primary" />
                    </div>
                    <Badge variant={isEnabled ? 'success' : 'secondary'}>
                        {isEnabled ? 'Enabled' : 'Disabled'}
                    </Badge>
                </div>
                <CardTitle className="text-lg mt-3">{name}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
                <p className="text-sm text-muted-foreground">{description}</p>
                <div className="flex items-center justify-between">
                    <Badge variant="outline">{category}</Badge>
                    <Button variant="ghost" size="sm" className="group-hover:translate-x-1 transition-transform">
                        Learn more <ArrowRight className="ml-1 h-3 w-3" />
                    </Button>
                </div>
            </CardContent>
        </Card>
    )
}
