import { useState, useEffect, useRef } from 'react';
import { Card } from '../components/Card';
import { Settings as SettingsIcon, Server, Key, Globe, Bell, Palette, CheckCircle, ExternalLink, Save, Loader2 } from 'lucide-react';
import { useBackendHealth, useAvailableTools } from '../hooks/useBackend';
import { notifySettingsUpdate } from '../context/ThemeContext';

// Default settings
const defaultSettings = {
    apiUrl: import.meta.env.VITE_API_URL || 'http://localhost:8000',
    refreshInterval: '30',
    notifications: {
        backendOffline: true,
        taskCompletion: true,
        calendarReminders: true,
        errors: false
    },
    theme: 'light',
    accentColor: '#8b5cf6'
};

// Load settings from localStorage
const loadSettings = () => {
    try {
        const saved = localStorage.getItem('vyana_dashboard_settings');
        if (saved) {
            const parsed = JSON.parse(saved);
            // Merge with defaults to ensure all keys exist
            return {
                ...defaultSettings,
                ...parsed,
                notifications: { ...defaultSettings.notifications, ...parsed.notifications }
            };
        }
    } catch (e) {
        console.error('Failed to load settings:', e);
    }
    return { ...defaultSettings };
};

export function Settings() {
    const { data: health } = useBackendHealth();
    const { data: tools } = useAvailableTools();

    // Settings state
    const [settings, setSettings] = useState(() => loadSettings());
    const [isSaving, setIsSaving] = useState(false);
    const [saveSuccess, setSaveSuccess] = useState(false);
    const [hasChanges, setHasChanges] = useState(false);

    // Store the initial/saved settings to compare against
    const savedSettingsRef = useRef(JSON.stringify(loadSettings()));

    // Track changes by comparing current settings to saved settings
    useEffect(() => {
        const currentStr = JSON.stringify(settings);
        setHasChanges(currentStr !== savedSettingsRef.current);
    }, [settings]);


    // Update settings helper
    const updateSetting = (key, value) => {
        setSettings(prev => ({ ...prev, [key]: value }));
    };

    const updateNotification = (key, value) => {
        setSettings(prev => ({
            ...prev,
            notifications: { ...prev.notifications, [key]: value }
        }));
    };

    // Save settings
    const handleSave = async () => {
        setIsSaving(true);
        setSaveSuccess(false);

        try {
            // Save to localStorage
            const settingsStr = JSON.stringify(settings);
            localStorage.setItem('vyana_dashboard_settings', settingsStr);

            // Update the ref so future changes are compared against this saved state
            savedSettingsRef.current = settingsStr;

            // Notify theme context to apply changes immediately
            notifySettingsUpdate();

            // Simulate a brief delay for UX
            await new Promise(resolve => setTimeout(resolve, 300));

            setSaveSuccess(true);
            setHasChanges(false);

            // Clear success message after 3 seconds
            setTimeout(() => setSaveSuccess(false), 3000);
        } catch (error) {
            console.error('Failed to save settings:', error);
            alert('Failed to save settings. Please try again.');
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <div className="p-8">
            {/* Header */}
            <div className="mb-8 flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-slate-800">Settings</h1>
                    <p className="text-slate-500 mt-1">Configure your dashboard and backend connection</p>
                </div>
                {saveSuccess && (
                    <div className="flex items-center gap-2 px-4 py-2 bg-green-100 text-green-700 rounded-xl">
                        <CheckCircle className="w-5 h-5" />
                        Settings saved successfully!
                    </div>
                )}
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Backend Configuration */}
                <Card>
                    <h2 className="text-lg font-semibold text-slate-800 mb-6 flex items-center gap-2">
                        <Server className="w-5 h-5 text-violet-600" />
                        Backend Configuration
                    </h2>
                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-slate-600 mb-2">API Base URL</label>
                            <div className="flex gap-2">
                                <input
                                    type="text"
                                    value={settings.apiUrl}
                                    onChange={(e) => updateSetting('apiUrl', e.target.value)}
                                    className="flex-1 px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-800 focus:border-violet-500 focus:outline-none focus:ring-2 focus:ring-violet-500/20 transition-colors"
                                />
                                <a
                                    href={settings.apiUrl}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="px-4 py-3 rounded-xl bg-violet-100 text-violet-600 hover:bg-violet-200 transition-colors"
                                >
                                    <ExternalLink className="w-5 h-5" />
                                </a>
                            </div>
                            <p className="text-xs text-slate-400 mt-2">
                                Set via VITE_API_URL environment variable or change here
                            </p>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-slate-600 mb-2">Connection Status</label>
                            <div className={`flex items-center gap-3 px-4 py-3 rounded-xl ${health ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
                                }`}>
                                <div className={`w-2 h-2 rounded-full ${health ? 'bg-green-500' : 'bg-red-500'} animate-pulse`} />
                                {health ? 'Connected to Backend' : 'Connection Failed'}
                            </div>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-slate-600 mb-2">Refresh Interval</label>
                            <select
                                value={settings.refreshInterval}
                                onChange={(e) => updateSetting('refreshInterval', e.target.value)}
                                className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-800"
                            >
                                <option value="10">10 seconds</option>
                                <option value="30">30 seconds</option>
                                <option value="60">1 minute</option>
                                <option value="300">5 minutes</option>
                            </select>
                        </div>
                    </div>
                </Card>

                {/* API Status */}
                <Card>
                    <h2 className="text-lg font-semibold text-slate-800 mb-6 flex items-center gap-2">
                        <Key className="w-5 h-5 text-violet-600" />
                        Backend Services
                    </h2>
                    <div className="space-y-3">
                        {[
                            { name: 'AI Chat (Groq)', status: health?.status === 'ok' },
                            { name: 'Voice Transcription', status: health?.status === 'ok' },
                            { name: 'Google Calendar', status: health?.status === 'ok' },
                            { name: 'Gmail Integration', status: health?.status === 'ok' },
                            { name: 'MCP Server', status: health?.status === 'ok' },
                        ].map((service) => (
                            <div key={service.name} className="flex items-center justify-between p-3 rounded-xl bg-slate-50">
                                <span className="text-slate-700">{service.name}</span>
                                <span className={`text-sm flex items-center gap-1 ${service.status ? 'text-green-600' : 'text-slate-400'}`}>
                                    {service.status && <CheckCircle className="w-4 h-4" />}
                                    {service.status ? 'Available' : 'Unavailable'}
                                </span>
                            </div>
                        ))}
                    </div>
                </Card>

                {/* Notifications */}
                <Card>
                    <h2 className="text-lg font-semibold text-slate-800 mb-6 flex items-center gap-2">
                        <Bell className="w-5 h-5 text-violet-600" />
                        Notifications
                    </h2>
                    <div className="space-y-4">
                        {[
                            { key: 'backendOffline', label: 'Backend offline alerts' },
                            { key: 'taskCompletion', label: 'Task completion notifications' },
                            { key: 'calendarReminders', label: 'Calendar reminders' },
                            { key: 'errors', label: 'Error notifications' },
                        ].map((item) => (
                            <label key={item.key} className="flex items-center justify-between cursor-pointer">
                                <span className="text-slate-700">{item.label}</span>
                                <input
                                    type="checkbox"
                                    checked={settings.notifications[item.key]}
                                    onChange={(e) => updateNotification(item.key, e.target.checked)}
                                    className="w-5 h-5 rounded accent-violet-600"
                                />
                            </label>
                        ))}
                    </div>
                </Card>

                {/* Appearance */}
                <Card>
                    <h2 className="text-lg font-semibold text-slate-800 mb-6 flex items-center gap-2">
                        <Palette className="w-5 h-5 text-violet-600" />
                        Appearance
                    </h2>
                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-slate-600 mb-2">Theme</label>
                            <select
                                value={settings.theme}
                                onChange={(e) => updateSetting('theme', e.target.value)}
                                className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-slate-800"
                            >
                                <option value="light">Light (Default)</option>
                                <option value="dark">Dark</option>
                                <option value="system">System</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-slate-600 mb-2">Accent Color</label>
                            <div className="flex gap-3">
                                {['#8b5cf6', '#ec4899', '#3b82f6', '#22c55e', '#f59e0b'].map((color) => (
                                    <button
                                        key={color}
                                        onClick={() => updateSetting('accentColor', color)}
                                        className={`w-10 h-10 rounded-xl transition-all shadow-md ${settings.accentColor === color
                                            ? 'ring-2 ring-offset-2 ring-slate-400 scale-110'
                                            : 'hover:scale-105'
                                            }`}
                                        style={{ backgroundColor: color }}
                                    />
                                ))}
                            </div>
                        </div>
                    </div>
                </Card>
            </div>

            {/* Save Button */}
            <div className="mt-8 flex justify-end gap-4">
                {hasChanges && (
                    <span className="self-center text-sm text-amber-600">You have unsaved changes</span>
                )}
                <button
                    onClick={handleSave}
                    disabled={isSaving || !hasChanges}
                    className={`px-6 py-3 rounded-xl font-semibold transition-all shadow-lg flex items-center gap-2 ${hasChanges
                        ? 'bg-gradient-to-r from-violet-600 to-indigo-600 text-white hover:opacity-90 shadow-violet-200'
                        : 'bg-slate-200 text-slate-500 cursor-not-allowed shadow-none'
                        }`}
                >
                    {isSaving ? (
                        <>
                            <Loader2 className="w-5 h-5 animate-spin" />
                            Saving...
                        </>
                    ) : (
                        <>
                            <Save className="w-5 h-5" />
                            Save Changes
                        </>
                    )}
                </button>
            </div>
        </div>
    );
}

