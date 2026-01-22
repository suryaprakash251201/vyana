import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
    getHealth,
    getBackendInfo,
    getTasks,
    createTask,
    completeTask,
    getTodayEvents,
    getCalendarEvents,
    getAvailableTools,
    testEndpoint
} from '../services/api';

// Health & Status
export function useBackendHealth() {
    return useQuery({
        queryKey: ['health'],
        queryFn: getHealth,
        refetchInterval: 30000, // Refresh every 30s
        retry: 1,
        staleTime: 10000,
    });
}

export function useBackendInfo() {
    return useQuery({
        queryKey: ['backendInfo'],
        queryFn: getBackendInfo,
        retry: 1,
    });
}

// Tasks
export function useTasks(includeCompleted = false) {
    return useQuery({
        queryKey: ['tasks', includeCompleted],
        queryFn: () => getTasks(includeCompleted),
        refetchInterval: 60000, // Refresh every minute
        staleTime: 30000,
    });
}

export function useCreateTask() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: ({ title, dueDate }) => createTask(title, dueDate),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['tasks'] });
        },
    });
}

export function useCompleteTask() {
    const queryClient = useQueryClient();
    return useMutation({
        mutationFn: (taskId) => completeTask(taskId),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['tasks'] });
        },
    });
}

// Calendar
export function useTodayEvents() {
    return useQuery({
        queryKey: ['todayEvents'],
        queryFn: getTodayEvents,
        refetchInterval: 300000, // Refresh every 5 min
        staleTime: 60000,
    });
}

export function useCalendarEvents(startDate, endDate) {
    return useQuery({
        queryKey: ['calendarEvents', startDate, endDate],
        queryFn: () => getCalendarEvents(startDate, endDate),
        enabled: !!startDate || !!endDate,
    });
}

// Tools
export function useAvailableTools() {
    return useQuery({
        queryKey: ['tools'],
        queryFn: getAvailableTools,
        staleTime: 300000,
    });
}

// Endpoint Testing
export function useEndpointTest(path, enabled = true) {
    return useQuery({
        queryKey: ['endpoint', path],
        queryFn: () => testEndpoint(path),
        enabled,
        refetchInterval: 60000,
        staleTime: 30000,
    });
}
