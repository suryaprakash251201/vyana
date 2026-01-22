import { createContext, useContext, useState, useEffect } from 'react';

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

// Theme Context
const ThemeContext = createContext(null);

export function ThemeProvider({ children }) {
    const [settings, setSettings] = useState(() => loadSettings());

    // Apply theme to document
    useEffect(() => {
        const root = document.documentElement;

        // Apply dark/light theme
        if (settings.theme === 'dark') {
            root.classList.add('dark');
        } else if (settings.theme === 'system') {
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            if (prefersDark) {
                root.classList.add('dark');
            } else {
                root.classList.remove('dark');
            }
        } else {
            root.classList.remove('dark');
        }

        // Apply accent color as CSS variable
        root.style.setProperty('--accent-color', settings.accentColor);

        // Generate accent color variants
        const hexToRgb = (hex) => {
            const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
            return result ? {
                r: parseInt(result[1], 16),
                g: parseInt(result[2], 16),
                b: parseInt(result[3], 16)
            } : null;
        };

        const rgb = hexToRgb(settings.accentColor);
        if (rgb) {
            root.style.setProperty('--accent-rgb', `${rgb.r}, ${rgb.g}, ${rgb.b}`);
        }
    }, [settings.theme, settings.accentColor]);

    // Listen for system theme changes
    useEffect(() => {
        if (settings.theme !== 'system') return;

        const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
        const handleChange = (e) => {
            if (e.matches) {
                document.documentElement.classList.add('dark');
            } else {
                document.documentElement.classList.remove('dark');
            }
        };

        mediaQuery.addEventListener('change', handleChange);
        return () => mediaQuery.removeEventListener('change', handleChange);
    }, [settings.theme]);

    // Reload settings when localStorage changes (for Settings page updates)
    useEffect(() => {
        const handleStorageChange = () => {
            setSettings(loadSettings());
        };

        // Custom event for same-tab updates
        window.addEventListener('vyana-settings-updated', handleStorageChange);
        // Storage event for cross-tab updates  
        window.addEventListener('storage', handleStorageChange);

        return () => {
            window.removeEventListener('vyana-settings-updated', handleStorageChange);
            window.removeEventListener('storage', handleStorageChange);
        };
    }, []);

    return (
        <ThemeContext.Provider value={{ settings, setSettings, reloadSettings: () => setSettings(loadSettings()) }}>
            {children}
        </ThemeContext.Provider>
    );
}

export function useTheme() {
    const context = useContext(ThemeContext);
    if (!context) {
        throw new Error('useTheme must be used within a ThemeProvider');
    }
    return context;
}

// Helper to notify theme changes from Settings page
export function notifySettingsUpdate() {
    window.dispatchEvent(new Event('vyana-settings-updated'));
}
