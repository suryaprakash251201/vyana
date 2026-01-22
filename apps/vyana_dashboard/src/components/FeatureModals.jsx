import { useState } from 'react';
import { X, Loader2, CheckCircle2, Circle, Plus, Calendar as CalendarIcon, ChevronLeft, ChevronRight } from 'lucide-react';
import { useTasks, useCompleteTask, useCreateTask, useTodayEvents } from '../hooks/useBackend';

// Tasks Panel Modal
export function TasksModal({ isOpen, onClose }) {
    const { data: tasks, isLoading, isError } = useTasks();
    const completeTaskMutation = useCompleteTask();
    const createTaskMutation = useCreateTask();
    const [newTaskTitle, setNewTaskTitle] = useState('');
    const [newTaskDueDate, setNewTaskDueDate] = useState('');

    const handleComplete = (taskId) => {
        completeTaskMutation.mutate(taskId);
    };

    const handleAddTask = () => {
        if (newTaskTitle.trim()) {
            createTaskMutation.mutate(
                { title: newTaskTitle.trim(), dueDate: newTaskDueDate || undefined },
                {
                    onSuccess: () => {
                        setNewTaskTitle('');
                        setNewTaskDueDate('');
                    }
                }
            );
        }
    };

    const handleKeyPress = (e) => {
        if (e.key === 'Enter') handleAddTask();
        if (e.key === 'Escape') onClose();
    };

    const displayTasks = tasks || [];
    const pendingTasks = displayTasks.filter(t => !t.is_completed);
    const completedTasks = displayTasks.filter(t => t.is_completed);

    if (!isOpen) return null;

    return (
        <>
            <div className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40" onClick={onClose} />
            <div className="fixed right-0 top-0 h-full w-full max-w-lg bg-white shadow-2xl z-50 flex flex-col animate-slide-in">
                {/* Header */}
                <div className="flex items-center justify-between p-4 border-b border-slate-100">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl">
                            <CheckCircle2 className="w-5 h-5 text-white" />
                        </div>
                        <div>
                            <h2 className="font-bold text-slate-800">Tasks</h2>
                            <p className="text-xs text-slate-500">{pendingTasks.length} pending tasks</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-xl transition-colors">
                        <X className="w-5 h-5 text-slate-500" />
                    </button>
                </div>

                {/* Add Task Form */}
                <div className="p-4 border-b border-slate-100 bg-slate-50">
                    <div className="flex gap-2">
                        <input
                            type="text"
                            value={newTaskTitle}
                            onChange={(e) => setNewTaskTitle(e.target.value)}
                            onKeyDown={handleKeyPress}
                            placeholder="Add a new task..."
                            className="flex-1 px-4 py-2 bg-white border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                        <input
                            type="date"
                            value={newTaskDueDate}
                            onChange={(e) => setNewTaskDueDate(e.target.value)}
                            className="px-3 py-2 bg-white border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                        <button
                            onClick={handleAddTask}
                            disabled={!newTaskTitle.trim() || createTaskMutation.isPending}
                            className="px-4 py-2 bg-blue-600 text-white rounded-xl text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
                        >
                            {createTaskMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
                        </button>
                    </div>
                </div>

                {/* Tasks List */}
                <div className="flex-1 overflow-y-auto p-4">
                    {isLoading ? (
                        <div className="flex items-center justify-center py-12">
                            <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
                        </div>
                    ) : isError ? (
                        <div className="text-center py-12 text-slate-400">
                            <p>Unable to load tasks. Check backend connection.</p>
                        </div>
                    ) : (
                        <>
                            {/* Pending Tasks */}
                            <div className="mb-6">
                                <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Pending</h3>
                                {pendingTasks.length === 0 ? (
                                    <p className="text-sm text-slate-400 text-center py-4">All tasks completed! 🎉</p>
                                ) : (
                                    <div className="space-y-2">
                                        {pendingTasks.map(task => (
                                            <div key={task.id} className="flex items-center gap-3 p-3 bg-slate-50 rounded-xl hover:bg-slate-100 transition-colors">
                                                <button
                                                    onClick={() => handleComplete(task.id)}
                                                    className="text-slate-300 hover:text-green-500 transition-colors"
                                                    disabled={completeTaskMutation.isPending}
                                                >
                                                    <Circle className="w-5 h-5" />
                                                </button>
                                                <div className="flex-1">
                                                    <p className="text-sm font-medium text-slate-700">{task.title}</p>
                                                    {task.due_date && (
                                                        <p className="text-xs text-slate-400">Due: {task.due_date}</p>
                                                    )}
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>

                            {/* Completed Tasks */}
                            {completedTasks.length > 0 && (
                                <div>
                                    <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Completed</h3>
                                    <div className="space-y-2">
                                        {completedTasks.slice(0, 5).map(task => (
                                            <div key={task.id} className="flex items-center gap-3 p-3 bg-green-50 rounded-xl opacity-60">
                                                <CheckCircle2 className="w-5 h-5 text-green-500" />
                                                <p className="text-sm text-slate-500 line-through">{task.title}</p>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </>
                    )}
                </div>
            </div>

            <style>{`
                @keyframes slideIn {
                    from { transform: translateX(100%); }
                    to { transform: translateX(0); }
                }
                .animate-slide-in {
                    animation: slideIn 0.2s ease-out;
                }
            `}</style>
        </>
    );
}

// Calendar Panel Modal
export function CalendarModal({ isOpen, onClose }) {
    const { data: eventsData, isLoading, isError } = useTodayEvents();
    const events = eventsData?.events || [];

    const getDays = () => {
        const today = new Date();
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const days = [];
        for (let i = -3; i <= 3; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() + i);
            days.push({
                d: dayNames[date.getDay()],
                n: date.getDate().toString(),
                active: i === 0,
                full: date.toISOString().split('T')[0]
            });
        }
        return days;
    };

    const days = getDays();
    const today = new Date();
    const currentMonth = today.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

    if (!isOpen) return null;

    return (
        <>
            <div className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40" onClick={onClose} />
            <div className="fixed right-0 top-0 h-full w-full max-w-lg bg-white shadow-2xl z-50 flex flex-col animate-slide-in">
                {/* Header */}
                <div className="flex items-center justify-between p-4 border-b border-slate-100">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-gradient-to-br from-cyan-500 to-blue-600 rounded-xl">
                            <CalendarIcon className="w-5 h-5 text-white" />
                        </div>
                        <div>
                            <h2 className="font-bold text-slate-800">Calendar</h2>
                            <p className="text-xs text-slate-500">{currentMonth}</p>
                        </div>
                    </div>
                    <button onClick={onClose} className="p-2 hover:bg-slate-100 rounded-xl transition-colors">
                        <X className="w-5 h-5 text-slate-500" />
                    </button>
                </div>

                {/* Week View */}
                <div className="p-4 border-b border-slate-100">
                    <div className="flex justify-between items-center">
                        <button className="p-2 hover:bg-slate-100 rounded-lg text-slate-400">
                            <ChevronLeft className="w-5 h-5" />
                        </button>
                        <div className="flex gap-4">
                            {days.map(day => (
                                <div key={day.full} className="flex flex-col items-center gap-2 cursor-pointer group">
                                    <span className="text-xs text-slate-400 font-medium uppercase">{day.d}</span>
                                    <div className={`
                                        w-10 h-10 rounded-full flex items-center justify-center text-sm font-bold transition-all
                                        ${day.active
                                            ? 'bg-blue-600 text-white shadow-lg shadow-blue-300 transform scale-110'
                                            : 'text-slate-700 group-hover:bg-slate-100'
                                        }
                                    `}>
                                        {day.n}
                                    </div>
                                </div>
                            ))}
                        </div>
                        <button className="p-2 hover:bg-slate-100 rounded-lg text-slate-400">
                            <ChevronRight className="w-5 h-5" />
                        </button>
                    </div>
                </div>

                {/* Events List */}
                <div className="flex-1 overflow-y-auto p-4">
                    <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-4">Today's Events</h3>

                    {isLoading ? (
                        <div className="flex items-center justify-center py-12">
                            <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
                        </div>
                    ) : isError ? (
                        <div className="text-center py-12 text-slate-400">
                            <p>Unable to load calendar events.</p>
                            <p className="text-xs mt-2">Make sure Google Calendar is connected in the backend.</p>
                        </div>
                    ) : events.length === 0 ? (
                        <div className="text-center py-12">
                            <CalendarIcon className="w-12 h-12 mx-auto text-slate-200 mb-4" />
                            <p className="text-slate-400">No events scheduled for today</p>
                        </div>
                    ) : (
                        <div className="space-y-3">
                            {events.map((event, idx) => (
                                <div key={idx} className="p-4 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-2xl border border-blue-100">
                                    <div className="flex items-start justify-between mb-2">
                                        <h4 className="font-semibold text-slate-800">{event.summary}</h4>
                                        {event.hangout_link && (
                                            <a
                                                href={event.hangout_link}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="px-3 py-1 bg-green-500 text-white text-xs font-medium rounded-lg hover:bg-green-600"
                                            >
                                                Join Meet
                                            </a>
                                        )}
                                    </div>
                                    <p className="text-sm text-slate-500">
                                        {event.start_time} - {event.end_time}
                                    </p>
                                    {event.location && (
                                        <p className="text-xs text-slate-400 mt-1">📍 {event.location}</p>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>

            <style>{`
                @keyframes slideIn {
                    from { transform: translateX(100%); }
                    to { transform: translateX(0); }
                }
                .animate-slide-in {
                    animation: slideIn 0.2s ease-out;
                }
            `}</style>
        </>
    );
}
