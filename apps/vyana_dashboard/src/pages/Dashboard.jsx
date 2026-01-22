import { useState } from 'react';
import { Search, Sparkles, Bot } from 'lucide-react';
import { BackendStatusWidget, TaskWidget, ProjectsWidget, CalendarWidget, GoalsWidget, RemindersWidget } from '../components/DashboardWidgets';
import { ChatModal } from '../components/ChatModal';
import vyanaLogo from '../assets/vyana-logo.png';

export function Dashboard() {
    const date = new Date().toLocaleDateString('en-US', { weekday: 'short', month: 'long', day: 'numeric' });
    const [isChatOpen, setIsChatOpen] = useState(false);

    return (
        <div className="p-8 lg:p-10 max-w-[1600px] mx-auto">
            {/* Header */}
            <div className="flex items-center justify-between mb-8">
                <div className="flex items-center gap-4">
                    <img src={vyanaLogo} alt="Vyana" className="w-14 h-14 rounded-2xl shadow-lg hover:rotate-3 transition-transform cursor-pointer" />
                    <div>
                        <h1 className="text-3xl font-bold text-slate-800">Vyana Dashboard</h1>
                        <p className="text-slate-500">{date} • AI Personal Assistant</p>
                    </div>
                </div>
                <div className="flex items-center gap-3">
                    <div className="relative">
                        <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                        <input
                            type="text"
                            className="pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-transparent w-64"
                            placeholder="Search..."
                        />
                    </div>
                    <button
                        onClick={() => setIsChatOpen(true)}
                        className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-violet-600 to-indigo-600 text-white rounded-xl font-semibold text-sm shadow-lg shadow-violet-200 hover:shadow-violet-300 hover:scale-105 transition-all"
                    >
                        <Sparkles className="w-4 h-4" />
                        Ask Vyana
                    </button>
                </div>
            </div>

            {/* Backend Status - Full Width */}
            <div className="mb-8">
                <BackendStatusWidget />
            </div>

            {/* Main Grid Layout */}
            <div className="grid grid-cols-12 gap-6">
                {/* Left Column - Tasks & Goals */}
                <div className="col-span-12 lg:col-span-5 space-y-6">
                    <div className="h-[420px]">
                        <TaskWidget />
                    </div>
                    <GoalsWidget />
                </div>

                {/* Right Column - Features, Calendar, Reminders */}
                <div className="col-span-12 lg:col-span-7 space-y-6">
                    <ProjectsWidget />
                    <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
                        <CalendarWidget />
                        <RemindersWidget />
                    </div>
                </div>
            </div>

            {/* Floating AI Button */}
            <div className="fixed bottom-8 right-8">
                <button
                    onClick={() => setIsChatOpen(true)}
                    className="w-14 h-14 bg-white rounded-full flex items-center justify-center shadow-xl shadow-violet-200 hover:scale-110 transition-transform border-4 border-violet-100"
                >
                    <img src={vyanaLogo} alt="Vyana" className="w-14 h-14 rounded-full" />
                </button>
            </div>

            {/* Chat Modal */}
            <ChatModal isOpen={isChatOpen} onClose={() => setIsChatOpen(false)} />
        </div>
    );
}

