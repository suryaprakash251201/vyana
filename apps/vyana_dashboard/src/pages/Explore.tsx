import { ToolCard } from '@/components/explore/ToolCard'
import { ApiExplorer } from '@/components/explore/ApiExplorer'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import {
    Compass,
    MessageSquare,
    Calendar,
    CheckSquare,
    Mail,
    Mic,
    Search as SearchIcon,
    Globe,
    Plug,
    Sparkles,
} from 'lucide-react'

const tools = [
    {
        name: 'Chat AI',
        description: 'Conversational AI powered by Google Gemini with streaming responses and tool calling.',
        icon: MessageSquare,
        category: 'AI',
        isEnabled: true,
    },
    {
        name: 'Task Management',
        description: 'Create, list, and complete tasks. Integrates with AI for natural language task creation.',
        icon: CheckSquare,
        category: 'Productivity',
        isEnabled: true,
    },
    {
        name: 'Calendar Integration',
        description: 'Access Google Calendar events. Create and manage appointments via voice or text.',
        icon: Calendar,
        category: 'Productivity',
        isEnabled: true,
    },
    {
        name: 'Email Access',
        description: 'Read unread emails and send messages through Gmail integration.',
        icon: Mail,
        category: 'Communication',
        isEnabled: true,
    },
    {
        name: 'Voice Transcription',
        description: 'Convert speech to text using Groq Whisper API for fast, accurate transcription.',
        icon: Mic,
        category: 'AI',
        isEnabled: true,
    },
    {
        name: 'Web Search',
        description: 'Search the web for real-time information using SERP API integration.',
        icon: Globe,
        category: 'Search',
        isEnabled: false,
    },
    {
        name: 'MCP Integration',
        description: 'Connect to Model Context Protocol servers for extended tool capabilities.',
        icon: Plug,
        category: 'Integration',
        isEnabled: true,
    },
    {
        name: 'Smart Suggestions',
        description: 'AI-powered suggestions based on your tasks, calendar, and communication patterns.',
        icon: Sparkles,
        category: 'AI',
        isEnabled: true,
    },
]

export function Explore() {
    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                <div>
                    <div className="flex items-center gap-2 mb-2">
                        <Compass className="h-5 w-5 text-primary" />
                        <Badge variant="secondary">Explore</Badge>
                    </div>
                    <h1 className="text-2xl font-bold">Explore Features</h1>
                    <p className="text-muted-foreground">
                        Discover all the tools and capabilities of your Vyana AI assistant
                    </p>
                </div>
                <div className="relative w-full md:w-64">
                    <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input placeholder="Search tools..." className="pl-9 bg-background/50" />
                </div>
            </div>

            {/* Tools Grid */}
            <div>
                <h2 className="text-lg font-semibold mb-4">Available Tools</h2>
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                    {tools.map((tool) => (
                        <ToolCard key={tool.name} {...tool} />
                    ))}
                </div>
            </div>

            {/* API Explorer Section */}
            <div className="grid gap-6 lg:grid-cols-2">
                <ApiExplorer />

                {/* Documentation Quick Links */}
                <Card className="glass">
                    <CardHeader className="pb-3">
                        <CardTitle className="text-lg">Documentation</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-3">
                        {[
                            { title: 'Getting Started', description: 'Learn the basics of Vyana API' },
                            { title: 'Authentication', description: 'OAuth 2.0 and API keys' },
                            { title: 'Chat Endpoints', description: 'AI conversation APIs' },
                            { title: 'Task Management', description: 'CRUD operations for tasks' },
                            { title: 'Calendar Integration', description: 'Google Calendar sync' },
                            { title: 'MCP Protocol', description: 'Model Context Protocol guide' },
                        ].map((doc) => (
                            <button
                                key={doc.title}
                                className="w-full flex items-center justify-between p-3 rounded-lg bg-muted/30 hover:bg-muted/50 transition-colors text-left"
                            >
                                <div>
                                    <p className="font-medium text-sm">{doc.title}</p>
                                    <p className="text-xs text-muted-foreground">{doc.description}</p>
                                </div>
                                <span className="text-primary text-sm">→</span>
                            </button>
                        ))}
                    </CardContent>
                </Card>
            </div>
        </div>
    )
}
