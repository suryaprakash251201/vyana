import { useAuth } from '@/context/AuthContext'
import { useTheme } from '@/context/ThemeContext'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Separator } from '@/components/ui/separator'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { useNavigate } from 'react-router-dom'
import { Settings as SettingsIcon, User, Bell, Shield, Palette, LogOut, FlaskConical, Sun, Moon } from 'lucide-react'

export function Settings() {
    const { user, isDemoMode, signOut } = useAuth()
    const { theme, setTheme } = useTheme()
    const navigate = useNavigate()

    const handleLogout = async () => {
        await signOut()
        navigate('/login')
    }

    const userInitials = user?.email
        ? user.email.substring(0, 2).toUpperCase()
        : 'U'

    return (
        <div className="space-y-6 max-w-4xl">
            {/* Header */}
            <div>
                <div className="flex items-center gap-2 mb-2">
                    <SettingsIcon className="h-5 w-5 text-primary" />
                    <Badge variant="secondary">Settings</Badge>
                </div>
                <h1 className="text-2xl font-bold">Settings</h1>
                <p className="text-muted-foreground">
                    Manage your account settings and preferences
                </p>
            </div>

            {/* Demo Mode Alert */}
            {isDemoMode && (
                <Card className="border-amber-500/30 bg-amber-500/5">
                    <CardContent className="p-4 flex items-center gap-3">
                        <FlaskConical className="h-5 w-5 text-amber-400" />
                        <div>
                            <p className="text-sm font-medium text-amber-400">Demo Mode Active</p>
                            <p className="text-xs text-muted-foreground">
                                Settings changes won't be saved. Configure Supabase to enable full functionality.
                            </p>
                        </div>
                    </CardContent>
                </Card>
            )}

            {/* Profile Section */}
            <Card className="glass">
                <CardHeader>
                    <CardTitle className="text-lg flex items-center gap-2">
                        <User className="h-5 w-5" />
                        Profile
                    </CardTitle>
                    <CardDescription>Your personal information</CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                    <div className="flex items-center gap-4">
                        <Avatar className="h-16 w-16">
                            <AvatarImage src={user?.user_metadata?.avatar_url} />
                            <AvatarFallback className="bg-primary text-primary-foreground text-xl">
                                {userInitials}
                            </AvatarFallback>
                        </Avatar>
                        <div>
                            <p className="font-medium">{user?.user_metadata?.full_name || 'User'}</p>
                            <p className="text-sm text-muted-foreground">{user?.email}</p>
                        </div>
                    </div>

                    <Separator />

                    <div className="grid gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <Label htmlFor="name">Display Name</Label>
                            <Input
                                id="name"
                                defaultValue={user?.user_metadata?.full_name || ''}
                                placeholder="Your name"
                                className="bg-background/50"
                                disabled={isDemoMode}
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="email">Email</Label>
                            <Input
                                id="email"
                                defaultValue={user?.email || ''}
                                disabled
                                className="bg-background/50"
                            />
                        </div>
                    </div>

                    <Button disabled={isDemoMode}>Save Changes</Button>
                </CardContent>
            </Card>

            {/* Notifications */}
            <Card className="glass">
                <CardHeader>
                    <CardTitle className="text-lg flex items-center gap-2">
                        <Bell className="h-5 w-5" />
                        Notifications
                    </CardTitle>
                    <CardDescription>Configure how you receive notifications</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                    {[
                        { label: 'Email notifications', description: 'Receive email updates' },
                        { label: 'Push notifications', description: 'Browser push notifications' },
                        { label: 'Task reminders', description: 'Reminders for upcoming tasks' },
                    ].map((item) => (
                        <div key={item.label} className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                            <div>
                                <p className="text-sm font-medium">{item.label}</p>
                                <p className="text-xs text-muted-foreground">{item.description}</p>
                            </div>
                            <Button variant="outline" size="sm" disabled={isDemoMode}>
                                Configure
                            </Button>
                        </div>
                    ))}
                </CardContent>
            </Card>

            {/* Appearance */}
            <Card className="glass">
                <CardHeader>
                    <CardTitle className="text-lg flex items-center gap-2">
                        <Palette className="h-5 w-5" />
                        Appearance
                    </CardTitle>
                    <CardDescription>Customize the look and feel</CardDescription>
                </CardHeader>
                <CardContent>
                    <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                        <div>
                            <p className="text-sm font-medium">Theme</p>
                            <p className="text-xs text-muted-foreground">
                                {theme === 'dark' ? 'Dark mode is active' : 'Light mode is active'}
                            </p>
                        </div>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
                        >
                            {theme === 'dark' ? (
                                <span className="flex items-center gap-2">
                                    <Moon className="h-4 w-4" /> Dark
                                </span>
                            ) : (
                                <span className="flex items-center gap-2">
                                    <Sun className="h-4 w-4" /> Light
                                </span>
                            )}
                        </Button>
                    </div>
                </CardContent>
            </Card>

            {/* Security */}
            <Card className="glass">
                <CardHeader>
                    <CardTitle className="text-lg flex items-center gap-2">
                        <Shield className="h-5 w-5" />
                        Security
                    </CardTitle>
                    <CardDescription>Manage your account security</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                    <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                        <div>
                            <p className="text-sm font-medium">Password</p>
                            <p className="text-xs text-muted-foreground">Change your password</p>
                        </div>
                        <Button variant="outline" size="sm" disabled={isDemoMode}>
                            Update
                        </Button>
                    </div>

                    <Separator />

                    <div className="pt-2">
                        <Button
                            variant="destructive"
                            className="w-full"
                            onClick={handleLogout}
                        >
                            <LogOut className="h-4 w-4 mr-2" />
                            Sign Out
                        </Button>
                    </div>
                </CardContent>
            </Card>
        </div>
    )
}
