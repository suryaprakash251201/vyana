import { useState } from 'react';
import { Card, IconButton } from './Card';
import {
    MoreHorizontal, Plus, Calendar as CalendarIcon, Clock, ChevronRight,
    CheckCircle2, Circle, ChevronLeft, Flag, Bell, Search, Filter, User,
    Folder, Video, Server, Wifi, WifiOff, Loader2
} from 'lucide-react';
import { useTasks, useCompleteTask, useCreateTask, useTodayEvents, useBackendHealth } from '../hooks/useBackend';

// Backend Status Widget
export function BackendStatusWidget() {
    const { data: health, isLoading, isError, error } = useBackendHealth();

    const getStatusInfo = () => {
        if (isLoading) return { status: 'checking', color: 'bg-yellow-500', text: 'Checking...' };
        if (isError || !health) return { status: 'offline', color: 'bg-red-500', text: 'Offline' };
        return { status: 'online', color: 'bg-green-500', text: 'Online' };
    };

    const statusInfo = getStatusInfo();

    return (
        <Card className="bg-gradient-to-br from-violet-600 to-indigo-700 text-white relative overflow-hidden">
            <div className="relative z-10">
                <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-white/20 rounded-xl">
                            {isLoading ? (
                                <Loader2 className="w-6 h-6 animate-spin" />
                            ) : statusInfo.status === 'online' ? (
                                <Wifi className="w-6 h-6" />
                            ) : (
                                <WifiOff className="w-6 h-6" />
                            )}
                        </div>
                        <div>
                            <h3 className="font-bold text-lg">Vyana Backend</h3>
                            <p className="text-white/70 text-sm">AI Assistant Server</p>
                        </div>
                    </div>
                    <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full ${statusInfo.status === 'online' ? 'bg-green-500/30' :
                        statusInfo.status === 'checking' ? 'bg-yellow-500/30' : 'bg-red-500/30'
                        }`}>
                        <div className={`w-2 h-2 rounded-full ${statusInfo.color} animate-pulse`} />
                        <span className="text-sm font-medium">{statusInfo.text}</span>
                    </div>
                </div>

                {health && (
                    <div className="grid grid-cols-2 gap-4 mt-4">
                        <div className="bg-white/10 rounded-xl p-3">
                            <p className="text-white/60 text-xs mb-1">Status</p>
                            <p className="font-semibold">{health.status || 'OK'}</p>
                        </div>
                        <div className="bg-white/10 rounded-xl p-3">
                            <p className="text-white/60 text-xs mb-1">Version</p>
                            <p className="font-semibold">{health.version || 'v0.1.0'}</p>
                        </div>
                    </div>
                )}
            </div>
            <div className="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full blur-2xl transform translate-x-10 -translate-y-10" />
            <div className="absolute bottom-0 left-0 w-24 h-24 bg-black/10 rounded-full blur-2xl transform -translate-x-8 translate-y-8" />
        </Card>
    );
}

// Task Widget connected to backend
export function TaskWidget() {
    const { data: tasks, isLoading, isError } = useTasks();
    const completeTaskMutation = useCompleteTask();
    const createTaskMutation = useCreateTask();
    const [isAddingTask, setIsAddingTask] = useState(false);
    const [newTaskTitle, setNewTaskTitle] = useState('');

    const handleComplete = (taskId) => {
        completeTaskMutation.mutate(taskId);
    };

    const handleAddTask = () => {
        if (newTaskTitle.trim()) {
            createTaskMutation.mutate({ title: newTaskTitle.trim() }, {
                onSuccess: () => {
                    setNewTaskTitle('');
                    setIsAddingTask(false);
                }
            });
        }
    };

    const handleKeyPress = (e) => {
        if (e.key === 'Enter') {
            handleAddTask();
        } else if (e.key === 'Escape') {
            setIsAddingTask(false);
            setNewTaskTitle('');
        }
    };

    // Fallback data when backend is unavailable
    const displayTasks = tasks || [];
    const pendingTasks = displayTasks.filter(t => !t.is_completed);

    return (
        <Card className="h-full relative overflow-hidden" noPadding>
            <div className="p-6 pb-2 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-indigo-50 rounded-xl">
                        <CheckCircle2 className="w-5 h-5 text-indigo-600" />
                    </div>
                    <h3 className="font-bold text-slate-800">My Tasks</h3>
                </div>
                <div className="flex gap-2">
                    <IconButton icon={Plus} onClick={() => setIsAddingTask(true)} />
                    <IconButton icon={MoreHorizontal} />
                </div>
            </div>

            <div className="px-6 py-4">
                <div className="flex items-center gap-2 mb-6">
                    <span className="px-3 py-1 bg-emerald-100 text-emerald-700 text-xs font-bold rounded-lg uppercase tracking-wider">
                        {isLoading ? 'Loading' : 'Active'}
                    </span>
                    <span className="text-slate-400 text-sm font-medium">
                        • {pendingTasks.length} tasks
                    </span>
                </div>

                {isLoading ? (
                    <div className="flex items-center justify-center py-8">
                        <Loader2 className="w-6 h-6 animate-spin text-indigo-600" />
                    </div>
                ) : isError ? (
                    <div className="text-center py-8 text-slate-400">
                        <WifiOff className="w-8 h-8 mx-auto mb-2 opacity-50" />
                        <p className="text-sm">Unable to load tasks</p>
                    </div>
                ) : pendingTasks.length === 0 ? (
                    <div className="text-center py-8 text-slate-400">
                        <CheckCircle2 className="w-8 h-8 mx-auto mb-2 opacity-50" />
                        <p className="text-sm">All tasks completed!</p>
                    </div>
                ) : (
                    <>
                        <div className="flex text-xs font-medium text-slate-400 mb-2 px-2">
                            <span className="flex-1">Name</span>
                            <span className="w-24 text-right">Due date</span>
                        </div>
                        <div className="space-y-1">
                            {pendingTasks.slice(0, 5).map(task => (
                                <div key={task.id} className="group flex items-center p-2 rounded-xl hover:bg-slate-50 transition-colors cursor-pointer">
                                    <button
                                        className="mr-3 text-slate-300 hover:text-indigo-600"
                                        onClick={() => handleComplete(task.id)}
                                    >
                                        <Circle className="w-5 h-5" />
                                    </button>
                                    <span className="flex-1 text-sm font-medium text-slate-700 group-hover:text-indigo-900">
                                        {task.title}
                                    </span>
                                    <div className="w-24 text-right">
                                        <span className="text-xs font-medium text-slate-500">
                                            {task.due_date || 'No date'}
                                        </span>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </>
                )}

                {isAddingTask ? (
                    <div className="mt-4 flex items-center gap-2 p-2 bg-slate-50 rounded-xl border border-indigo-200">
                        <Circle className="w-5 h-5 text-slate-300" />
                        <input
                            type="text"
                            value={newTaskTitle}
                            onChange={(e) => setNewTaskTitle(e.target.value)}
                            onKeyDown={handleKeyPress}
                            placeholder="Enter task title..."
                            autoFocus
                            className="flex-1 bg-transparent text-sm text-slate-700 placeholder-slate-400 focus:outline-none"
                        />
                        <button
                            onClick={handleAddTask}
                            disabled={!newTaskTitle.trim() || createTaskMutation.isPending}
                            className="px-3 py-1 bg-indigo-600 text-white text-xs font-medium rounded-lg hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                        >
                            {createTaskMutation.isPending ? 'Adding...' : 'Add'}
                        </button>
                        <button
                            onClick={() => { setIsAddingTask(false); setNewTaskTitle(''); }}
                            className="px-2 py-1 text-slate-400 hover:text-slate-600 text-xs"
                        >
                            Cancel
                        </button>
                    </div>
                ) : (
                    <button
                        onClick={() => setIsAddingTask(true)}
                        className="mt-4 flex items-center gap-2 text-sm font-medium text-slate-500 hover:text-indigo-600 p-2 rounded-lg hover:bg-slate-50 w-full transition-colors"
                    >
                        <Plus className="w-4 h-4" /> Add task
                    </button>
                )}
            </div>

            <div className="px-6 pb-6 space-y-2 mt-2">
                {['Completed', 'Upcoming'].map(section => (
                    <div key={section} className="flex items-center gap-2 p-2 rounded-xl text-slate-400 hover:bg-slate-50 cursor-pointer">
                        <ChevronRight className="w-4 h-4" />
                        <span className="px-2 py-0.5 bg-slate-100 text-slate-500 text-[10px] font-bold rounded uppercase">{section}</span>
                    </div>
                ))}
            </div>
        </Card>
    );
}

export function ProjectsWidget() {
    const projects = [
        { title: 'Create new project', icon: Plus, color: 'bg-indigo-50 text-indigo-600', dashed: true },
        { title: 'AI Chat', subtitle: 'Voice & text interactions', icon: Flag, color: 'bg-purple-100 text-purple-600' },
        { title: 'Calendar Sync', subtitle: 'Google Calendar integration', icon: User, color: 'bg-blue-100 text-blue-600' },
        { title: 'Task Manager', subtitle: 'AI-powered task creation', icon: Search, color: 'bg-cyan-100 text-cyan-600' },
    ];

    return (
        <Card noPadding>
            <div className="p-6 pb-2 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-purple-50 rounded-xl">
                        <Folder className="w-5 h-5 text-purple-600" />
                    </div>
                    <h3 className="font-bold text-slate-800">Features</h3>
                </div>
                <button className="text-xs font-medium text-slate-400 hover:text-slate-600">View all</button>
            </div>
            <div className="p-6 grid grid-cols-2 gap-4">
                {projects.map((p, i) => (
                    <div
                        key={i}
                        className={`
                            p-4 rounded-2xl flex flex-col gap-3 cursor-pointer transition-all duration-200
                            ${p.dashed
                                ? 'border-2 border-dashed border-slate-200 hover:border-indigo-400 hover:bg-indigo-50/50'
                                : 'bg-slate-50 hover:bg-white hover:shadow-md border border-slate-100'
                            }
                        `}
                    >
                        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${p.color}`}>
                            <p.icon className="w-5 h-5" />
                        </div>
                        <div>
                            <h4 className="font-bold text-sm text-slate-800">{p.title}</h4>
                            {p.subtitle && <p className="text-[10px] text-slate-500 mt-1">{p.subtitle}</p>}
                        </div>
                    </div>
                ))}
            </div>
        </Card>
    );
}

export function CalendarWidget() {
    const { data: eventsData, isLoading } = useTodayEvents();
    const events = eventsData?.events || [];

    // Generate dynamic week days centered around today
    const getDays = () => {
        const today = new Date();
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const days = [];

        // Start from 3 days before today
        for (let i = -3; i <= 3; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() + i);
            days.push({
                d: dayNames[date.getDay()],
                n: date.getDate().toString(),
                active: i === 0 // Today is active
            });
        }
        return days;
    };

    const days = getDays();

    // Get current month name
    const currentMonth = new Date().toLocaleDateString('en-US', { month: 'long' });

    return (
        <Card noPadding>
            <div className="p-6 pb-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                    <div className="p-2 bg-indigo-50 rounded-xl">
                        <CalendarIcon className="w-5 h-5 text-indigo-600" />
                    </div>
                    <h3 className="font-bold text-slate-800">Calendar</h3>
                </div>
                <button className="text-xs font-medium text-slate-400 hover:text-slate-600">{currentMonth} ▼</button>
            </div>

            <div className="px-6 mb-6">
                <div className="flex justify-between items-center mb-6">
                    <button className="p-1 hover:bg-slate-100 rounded-lg text-slate-400"><ChevronLeft className="w-4 h-4" /></button>
                    <div className="flex gap-4">
                        {days.map(day => (
                            <div key={day.n} className="flex flex-col items-center gap-2 cursor-pointer group">
                                <span className="text-[10px] text-slate-400 font-medium uppercase">{day.d}</span>
                                <div className={`
                                     w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-all
                                     ${day.active
                                        ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-300 transform scale-110'
                                        : 'text-slate-700 group-hover:bg-slate-100'
                                    }
                                 `}>
                                    {day.n}
                                </div>
                            </div>
                        ))}
                    </div>
                    <button className="p-1 hover:bg-slate-100 rounded-lg text-slate-400"><ChevronRight className="w-4 h-4" /></button>
                </div>

                {isLoading ? (
                    <div className="flex items-center justify-center py-8">
                        <Loader2 className="w-6 h-6 animate-spin text-indigo-600" />
                    </div>
                ) : events.length === 0 ? (
                    <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100 text-center">
                        <p className="text-slate-400 text-sm">No events today</p>
                    </div>
                ) : (
                    <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100 hover:shadow-md transition-shadow relative overflow-hidden group">
                        <div className="relative z-10">
                            <h4 className="font-bold text-slate-800 mb-1">{events[0]?.summary || 'Event'}</h4>
                            <p className="text-xs text-slate-500 mb-4">Today • {events[0]?.start_time || 'All day'}</p>
                            <div className="flex items-center justify-between">
                                <button className="flex items-center gap-2 px-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-semibold text-slate-600 hover:text-indigo-600 transition-colors">
                                    <Video className="w-3 h-3 text-green-500" />
                                    Join Meeting
                                </button>
                            </div>
                        </div>
                        <div className="absolute top-0 right-0 w-32 h-32 bg-indigo-500/5 rounded-full blur-3xl transform translate-x-10 -translate-y-10 group-hover:bg-indigo-500/10 transition-colors" />
                    </div>
                )}
            </div>
        </Card>
    );
}

export function GoalsWidget() {
    const goals = [
        { title: 'Voice Commands Setup', sub: 'AI Integration', progress: 100, color: 'bg-green-400' },
        { title: 'Calendar Sync', sub: 'Google Calendar', progress: 85, color: 'bg-teal-400' },
        { title: 'Task Management', sub: 'Backend Integration', progress: 70, color: 'bg-cyan-400' },
    ];

    return (
        <Card noPadding>
            <div className="p-6 pb-4 flex items-center gap-3">
                <div className="p-2 bg-purple-50 rounded-xl">
                    <CheckCircle2 className="w-5 h-5 text-purple-600" />
                </div>
                <h3 className="font-bold text-slate-800">Integration Status</h3>
            </div>

            <div className="px-6 pb-6 space-y-6">
                {goals.map((goal, i) => (
                    <div key={i}>
                        <div className="flex justify-between items-end mb-2">
                            <div>
                                <h4 className="font-bold text-sm text-slate-800">{goal.title}</h4>
                                <p className="text-[10px] text-slate-400 mt-0.5">{goal.sub}</p>
                            </div>
                            <span className="font-bold text-sm text-slate-800">{goal.progress}%</span>
                        </div>
                        <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                            <div className={`h-full rounded-full ${goal.color}`} style={{ width: `${goal.progress}%` }} />
                        </div>
                    </div>
                ))}
            </div>
        </Card>
    );
}

export function RemindersWidget() {
    return (
        <Card noPadding>
            <div className="p-6 pb-0 flex items-center gap-3">
                <Clock className="w-5 h-5 text-slate-400" />
                <h3 className="font-bold text-slate-800">Reminders</h3>
            </div>
            <div className="p-6">
                <div className="flex items-center gap-2 mb-4">
                    <ChevronRight className="w-4 h-4 text-slate-400" />
                    <span className="text-xs font-bold text-slate-800">Today</span>
                    <span className="px-1.5 py-0.5 bg-slate-100 rounded text-[10px] text-slate-500 font-bold">2</span>
                </div>

                <div className="space-y-4 pl-6 border-l border-slate-100 ml-2">
                    <div className="relative pl-6">
                        <div className="absolute left-[-5px] top-1.5 w-2.5 h-2.5 rounded-full border-2 border-white bg-violet-400 shadow-sm" />
                        <h4 className="text-sm text-slate-700 font-medium">Check Vyana backend status</h4>
                        <div className="flex gap-4 mt-2">
                            <Bell className="w-4 h-4 text-slate-300 hover:text-indigo-600 cursor-pointer" />
                            <CheckCircle2 className="w-4 h-4 text-slate-300 hover:text-green-600 cursor-pointer" />
                        </div>
                    </div>
                    <div className="relative pl-6">
                        <div className="absolute left-[-5px] top-1.5 w-2.5 h-2.5 rounded-full border-2 border-white bg-blue-400 shadow-sm" />
                        <h4 className="text-sm text-slate-700 font-medium">Review AI assistant responses</h4>
                    </div>
                </div>
            </div>
        </Card>
    );
}
