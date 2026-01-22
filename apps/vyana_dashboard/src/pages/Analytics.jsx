import { Card } from '../components/Card';
import { BarChart3, TrendingUp, MessageSquare, Mic, CheckSquare } from 'lucide-react';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

const messagesData = [
    { name: 'Mon', messages: 120, voice: 45 },
    { name: 'Tue', messages: 180, voice: 62 },
    { name: 'Wed', messages: 150, voice: 55 },
    { name: 'Thu', messages: 220, voice: 78 },
    { name: 'Fri', messages: 200, voice: 70 },
    { name: 'Sat', messages: 80, voice: 30 },
    { name: 'Sun', messages: 60, voice: 25 },
];

const taskStatusData = [
    { name: 'Completed', value: 45, color: '#22c55e' },
    { name: 'In Progress', value: 30, color: '#8b5cf6' },
    { name: 'Pending', value: 25, color: '#f59e0b' },
];

const hourlyData = Array.from({ length: 24 }, (_, i) => ({
    hour: `${i}:00`,
    requests: Math.floor(Math.random() * 50) + 10,
}));

export function Analytics() {
    return (
        <div className="p-8">
            {/* Header */}
            <div className="flex items-center justify-between mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-[var(--text)]">Analytics</h1>
                    <p className="text-[var(--text-muted)] mt-1">Insights and usage statistics for your AI assistant</p>
                </div>
                <select className="px-4 py-2 rounded-xl bg-[var(--surface)] border border-[var(--surface-light)] text-[var(--text)]">
                    <option>Last 7 days</option>
                    <option>Last 30 days</option>
                    <option>Last 90 days</option>
                </select>
            </div>

            {/* Summary Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <Card>
                    <div className="flex items-center justify-between mb-2">
                        <span className="text-[var(--text-muted)]">Total Messages</span>
                        <MessageSquare className="w-5 h-5 text-violet-400" />
                    </div>
                    <p className="text-3xl font-bold text-[var(--text)]">1,010</p>
                    <p className="text-sm text-green-400 mt-2 flex items-center gap-1">
                        <TrendingUp className="w-4 h-4" /> +15% from last week
                    </p>
                </Card>

                <Card>
                    <div className="flex items-center justify-between mb-2">
                        <span className="text-[var(--text-muted)]">Voice Interactions</span>
                        <Mic className="w-5 h-5 text-pink-400" />
                    </div>
                    <p className="text-3xl font-bold text-[var(--text)]">365</p>
                    <p className="text-sm text-green-400 mt-2 flex items-center gap-1">
                        <TrendingUp className="w-4 h-4" /> +8% from last week
                    </p>
                </Card>

                <Card>
                    <div className="flex items-center justify-between mb-2">
                        <span className="text-[var(--text-muted)]">Tasks Completed</span>
                        <CheckSquare className="w-5 h-5 text-blue-400" />
                    </div>
                    <p className="text-3xl font-bold text-[var(--text)]">89</p>
                    <p className="text-sm text-green-400 mt-2 flex items-center gap-1">
                        <TrendingUp className="w-4 h-4" /> +23% from last week
                    </p>
                </Card>
            </div>

            {/* Charts Row 1 */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
                {/* Messages Over Time */}
                <Card>
                    <h2 className="text-lg font-semibold text-[var(--text)] mb-6 flex items-center gap-2">
                        <BarChart3 className="w-5 h-5 text-violet-400" />
                        Messages & Voice Activity
                    </h2>
                    <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={messagesData}>
                                <defs>
                                    <linearGradient id="colorMessages" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.3} />
                                        <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0} />
                                    </linearGradient>
                                    <linearGradient id="colorVoice" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#ec4899" stopOpacity={0.3} />
                                        <stop offset="95%" stopColor="#ec4899" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                                <XAxis dataKey="name" stroke="#94a3b8" />
                                <YAxis stroke="#94a3b8" />
                                <Tooltip
                                    contentStyle={{
                                        backgroundColor: '#1e293b',
                                        border: '1px solid #334155',
                                        borderRadius: '12px',
                                        color: '#f1f5f9'
                                    }}
                                />
                                <Area type="monotone" dataKey="messages" stroke="#8b5cf6" fillOpacity={1} fill="url(#colorMessages)" />
                                <Area type="monotone" dataKey="voice" stroke="#ec4899" fillOpacity={1} fill="url(#colorVoice)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </Card>

                {/* Task Status */}
                <Card>
                    <h2 className="text-lg font-semibold text-[var(--text)] mb-6 flex items-center gap-2">
                        <CheckSquare className="w-5 h-5 text-violet-400" />
                        Task Distribution
                    </h2>
                    <div className="h-64 flex items-center justify-center">
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie
                                    data={taskStatusData}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={60}
                                    outerRadius={90}
                                    paddingAngle={5}
                                    dataKey="value"
                                >
                                    {taskStatusData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={entry.color} />
                                    ))}
                                </Pie>
                                <Tooltip
                                    contentStyle={{
                                        backgroundColor: '#1e293b',
                                        border: '1px solid #334155',
                                        borderRadius: '12px',
                                        color: '#f1f5f9'
                                    }}
                                />
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                    <div className="flex justify-center gap-6 mt-4">
                        {taskStatusData.map((item) => (
                            <div key={item.name} className="flex items-center gap-2">
                                <div className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }} />
                                <span className="text-sm text-[var(--text-muted)]">{item.name}</span>
                            </div>
                        ))}
                    </div>
                </Card>
            </div>

            {/* Hourly Activity */}
            <Card>
                <h2 className="text-lg font-semibold text-[var(--text)] mb-6 flex items-center gap-2">
                    <BarChart3 className="w-5 h-5 text-violet-400" />
                    Hourly Activity (Today)
                </h2>
                <div className="h-48">
                    <ResponsiveContainer width="100%" height="100%">
                        <BarChart data={hourlyData}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                            <XAxis dataKey="hour" stroke="#94a3b8" fontSize={10} />
                            <YAxis stroke="#94a3b8" />
                            <Tooltip
                                contentStyle={{
                                    backgroundColor: '#1e293b',
                                    border: '1px solid #334155',
                                    borderRadius: '12px',
                                    color: '#f1f5f9'
                                }}
                            />
                            <Bar dataKey="requests" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </Card>
        </div>
    );
}
