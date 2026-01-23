const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://vyana.suryaprakashinfo.in'

interface ApiResponse<T> {
    data?: T
    error?: string
}

async function fetchApi<T>(
    endpoint: string,
    options: RequestInit = {}
): Promise<ApiResponse<T>> {
    try {
        const url = `${API_BASE_URL}${endpoint}`
        console.log(`[API] Fetching: ${url}`)

        const response = await fetch(url, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers,
            },
        })

        if (!response.ok) {
            console.error(`[API] Error ${response.status}: ${response.statusText} for ${url}`)
            const errorData = await response.json().catch(() => ({}))
            return { error: errorData.detail || `HTTP ${response.status}: ${response.statusText}` }
        }

        const data = await response.json()
        return { data }
    } catch (error) {
        console.error(`[API] Network error for ${endpoint}:`, error)
        return { error: error instanceof Error ? error.message : 'Network error - Check your connection' }
    }
}

// Health endpoints
export async function getHealth() {
    return fetchApi<{ status: string; version: string }>('/health')
}

// Chat endpoints
export async function sendChatMessage(message: string, conversationId?: string) {
    return fetchApi<{ response: string; conversation_id: string }>('/chat/send', {
        method: 'POST',
        body: JSON.stringify({
            messages: [{ role: 'user', content: message }],
            conversation_id: conversationId,
            settings: { tools_enabled: true },
        }),
    })
}

// Tasks endpoints
export async function getTasks() {
    return fetchApi<Array<{
        id: string
        title: string
        due_date: string
        is_completed: boolean
        created_at: string
    }>>('/tasks/list')
}

export async function createTask(title: string, dueDate?: string) {
    return fetchApi<{ id: string; title: string }>('/tasks/create', {
        method: 'POST',
        body: JSON.stringify({ title, due_date: dueDate }),
    })
}

// Calendar endpoints
export async function getTodayEvents() {
    return fetchApi<Array<{
        id: string
        summary: string
        start: string
        end: string
    }>>('/calendar/today')
}

// MCP endpoints
export async function getMcpServers() {
    return fetchApi<Array<{
        name: string
        status: string
        tools: string[]
    }>>('/mcp/servers')
}

export async function connectMcpServer(serverUrl: string) {
    return fetchApi<{ status: string }>('/mcp/connect', {
        method: 'POST',
        body: JSON.stringify({ server_url: serverUrl }),
    })
}

// Tools endpoints
export async function getAvailableTools() {
    return fetchApi<Array<{
        name: string
        description: string
        enabled: boolean
    }>>('/tools/list')
}

// Monitoring endpoints
export async function getSystemStats() {
    return fetchApi<{
        cpu: { percent: number; cores: number[] }
        memory: { total: number; available: number; used: number; percent: number }
        disk: { total: number; used: number; free: number; percent: number }
        network: { bytes_sent: number; bytes_recv: number }
        uptime: string
        platform: string
    }>('/monitoring/system')
}

export { API_BASE_URL }
