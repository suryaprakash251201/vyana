import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Activity, BarChart3, Settings, MessageSquare, Calendar as CalendarIcon, CheckSquare, Cpu } from 'lucide-react';
import vyanaLogo from '../assets/vyana-logo.png';

const mainNavItems = [
    { to: '/', label: 'Dashboard', icon: LayoutDashboard },
    { to: '/monitor', label: 'System Monitor', icon: Activity },
    { to: '/analytics', label: 'Analytics', icon: BarChart3 },
];

const featureItems = [
    { id: 'chat', label: 'AI Chat', icon: MessageSquare, color: 'bg-violet-500' },
    { id: 'tasks', label: 'Tasks', icon: CheckSquare, color: 'bg-blue-500' },
    { id: 'calendar', label: 'Calendar', icon: CalendarIcon, color: 'bg-cyan-500' },
];

export function Sidebar({ onFeatureClick }) {
    return (
        <aside className="w-64 min-h-screen border-r border-slate-100 p-6 flex flex-col fixed left-0 top-0 bottom-0 z-10" style={{ backgroundColor: 'var(--sidebar-bg)' }}>
            {/* Brand Header */}
            <div className="flex items-center gap-3 mb-10 pl-2">
                <img src={vyanaLogo} alt="Vyana" className="w-10 h-10 rounded-xl shadow-lg" />
                <div>
                    <h2 className="text-lg font-bold text-slate-800">Vyana</h2>
                    <p className="text-xs text-slate-500">AI Assistant Dashboard</p>
                </div>
            </div>

            {/* Main Navigation */}
            <nav className="space-y-1 mb-8">
                {mainNavItems.map(({ to, label, icon: Icon }) => (
                    <NavLink
                        key={label}
                        to={to}
                        className={({ isActive }) => `
              flex items-center gap-3 px-4 py-3 rounded-2xl
              transition-all duration-200 font-medium text-sm
              ${isActive
                                ? 'bg-violet-50 text-violet-700 shadow-sm'
                                : 'text-slate-500 hover:text-slate-900 hover:bg-slate-50'
                            }
            `}
                    >
                        {({ isActive }) => (
                            <>
                                <Icon className={`w-5 h-5 ${isActive ? 'text-violet-600' : 'text-slate-400'}`} />
                                <span>{label}</span>
                            </>
                        )}
                    </NavLink>
                ))}
            </nav>

            {/* Features Section */}
            <div className="mb-auto">
                <div className="flex items-center justify-between px-4 mb-4">
                    <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Features</h3>
                </div>
                <div className="space-y-1">
                    {featureItems.map((item) => (
                        <button
                            key={item.id}
                            onClick={() => onFeatureClick && onFeatureClick(item.id)}
                            className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-slate-600 hover:bg-slate-50 hover:text-slate-900 transition-colors text-sm font-medium"
                        >
                            <div className={`w-2.5 h-2.5 rounded-lg ${item.color}`} />
                            {item.label}
                        </button>
                    ))}
                </div>
            </div>

            {/* Bottom Settings */}
            <div className="mt-6 pt-6 border-t border-slate-100">
                <NavLink
                    to="/settings"
                    className={({ isActive }) => `
              flex items-center gap-3 px-4 py-3 rounded-2xl
              transition-all duration-200 font-medium text-sm
              ${isActive
                            ? 'bg-violet-50 text-violet-700 shadow-sm'
                            : 'text-slate-500 hover:text-slate-900 hover:bg-slate-50'
                        }
            `}
                >
                    <Settings className="w-5 h-5 text-slate-400" />
                    <span>Settings</span>
                </NavLink>

                {/* Backend Status Card */}
                <div className="mt-4 p-4 rounded-2xl bg-gradient-to-br from-violet-600 to-indigo-600 text-white relative overflow-hidden">
                    <div className="relative z-10">
                        <div className="flex items-center gap-2 mb-2">
                            <Cpu className="w-4 h-4" />
                            <h4 className="font-bold text-sm">Vyana Backend</h4>
                        </div>
                        <p className="text-[10px] text-white/80 leading-relaxed mb-3">
                            Connected to AI server for chat, tasks, and calendar management
                        </p>
                        <a
                            href="https://vyana.suryaprakashinfo.in"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="block w-full py-1.5 bg-white text-violet-600 text-xs font-bold rounded-lg hover:bg-slate-50 transition-colors text-center"
                        >
                            View API Docs
                        </a>
                    </div>
                    <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 rounded-full blur-xl transform translate-x-8 -translate-y-8" />
                    <div className="absolute bottom-0 left-0 w-24 h-24 bg-black/10 rounded-full blur-xl transform -translate-x-8 translate-y-8" />
                </div>
            </div>
        </aside>
    );
}
