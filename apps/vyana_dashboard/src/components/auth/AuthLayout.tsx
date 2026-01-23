import { Zap } from 'lucide-react'

interface AuthLayoutProps {
    children: React.ReactNode
    title: string
    subtitle: string
}

export function AuthLayout({ children, title, subtitle }: AuthLayoutProps) {
    return (
        <div className="min-h-screen flex gradient-bg">
            {/* Left side - Branding */}
            <div className="hidden lg:flex lg:w-1/2 flex-col justify-between p-12 relative overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-primary/20 via-transparent to-purple-500/20" />

                <div className="relative z-10">
                    <div className="flex items-center gap-3">
                        <div className="h-10 w-10 rounded-xl gradient-primary flex items-center justify-center">
                            <Zap className="h-6 w-6 text-white" />
                        </div>
                        <span className="text-2xl font-bold text-gradient">Vyana</span>
                    </div>
                </div>

                <div className="relative z-10 space-y-4">
                    <h1 className="text-4xl font-bold leading-tight">
                        Your AI Executive<br />
                        <span className="text-gradient">Assistant Dashboard</span>
                    </h1>
                    <p className="text-muted-foreground text-lg max-w-md">
                        Monitor, manage, and explore your personal AI assistant with a powerful dashboard interface.
                    </p>
                </div>

                <div className="relative z-10">
                    <p className="text-sm text-muted-foreground">
                        © 2026 Vyana AI. All rights reserved.
                    </p>
                </div>

                {/* Decorative elements */}
                <div className="absolute top-1/4 right-0 w-64 h-64 bg-primary/10 rounded-full blur-3xl" />
                <div className="absolute bottom-1/4 left-0 w-48 h-48 bg-purple-500/10 rounded-full blur-3xl" />
            </div>

            {/* Right side - Auth form */}
            <div className="w-full lg:w-1/2 flex items-center justify-center p-8">
                <div className="w-full max-w-md">
                    {/* Mobile logo */}
                    <div className="flex lg:hidden items-center gap-3 mb-8 justify-center">
                        <div className="h-10 w-10 rounded-xl gradient-primary flex items-center justify-center">
                            <Zap className="h-6 w-6 text-white" />
                        </div>
                        <span className="text-2xl font-bold text-gradient">Vyana</span>
                    </div>

                    <div className="glass-strong rounded-2xl p-8">
                        <div className="text-center mb-8">
                            <h2 className="text-2xl font-bold">{title}</h2>
                            <p className="text-muted-foreground mt-2">{subtitle}</p>
                        </div>
                        {children}
                    </div>
                </div>
            </div>
        </div>
    )
}
