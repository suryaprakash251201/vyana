import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

const api = axios.create({
    baseURL: API_BASE_URL,
    timeout: 10000,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Health check
export const getHealth = async () => {
    const response = await api.get('health');
    return response.data;
};

// Backend info
export const getBackendInfo = async () => {
    const response = await api.get('');
    return response.data;
};

// Tasks
export const getTasks = async (includeCompleted = false) => {
    const response = await api.get('tasks/list', {
        params: { include_completed: includeCompleted }
    });
    return response.data;
};

export const createTask = async (title, dueDate = null) => {
    const response = await api.post('tasks/create', {
        title,
        due_date: dueDate
    });
    return response.data;
};

export const completeTask = async (taskId) => {
    const response = await api.post('tasks/complete', {
        task_id: taskId
    });
    return response.data;
};

// Calendar
export const getCalendarEvents = async (startDate = null, endDate = null) => {
    const response = await api.get('calendar/events', {
        params: { start: startDate, end: endDate }
    });
    return response.data;
};

export const getTodayEvents = async () => {
    const response = await api.get('calendar/today');
    return response.data;
};

export const createCalendarEvent = async (summary, startTime, durationMinutes = 60, description = null) => {
    const response = await api.post('calendar/create', {
        summary,
        start_time: startTime,
        duration_minutes: durationMinutes,
        description
    });
    return response.data;
};

// Gmail
export const getUnreadEmails = async () => {
    const response = await api.get('gmail/unread');
    return response.data;
};

// Tools
export const getAvailableTools = async () => {
    const response = await api.get('tools/list');
    return response.data;
};

export const toggleTool = async (toolName, enabled) => {
    const response = await api.post('tools/toggle', {
        tool_name: toolName,
        enabled
    });
    return response.data;
};

// Chat
export const sendChatMessage = async (message, conversationId = null, toolsEnabled = true) => {
    const response = await api.post('chat/send', {
        message,
        conversation_id: conversationId,
        tools_enabled: toolsEnabled
    });
    return response.data;
};

// Test endpoint connectivity
export const testEndpoint = async (path) => {
    const startTime = Date.now();
    try {
        await api.get(path, { timeout: 5000 });
        return {
            status: 'online',
            latency: `${Date.now() - startTime}ms`
        };
    } catch (error) {
        if (error.code === 'ECONNABORTED') {
            return { status: 'timeout', latency: '>5000ms' };
        }
        return { status: 'offline', latency: '-' };
    }
};

export default api;
