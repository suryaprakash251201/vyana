import { useState, useEffect } from 'react';
import { Server, Cpu, HardDrive, Wifi, Clock, CheckCircle, XCircle, AlertCircle, RefreshCw, Loader2 } from 'lucide-react';
import { Card } from '../components/Card';
import { StatusBadge } from '../components/StatusBadge';
import { useBackendHealth, useBackendInfo } from '../hooks/useBackend';
import { testEndpoint } from '../services/api';

export function Monitor() {
    const { data: health, isLoading: healthLoading, refetch: refetchHealth } = useBackendHealth();
    const { data: backendInfo } = useBackendInfo();
    const [lastUpdate, setLastUpdate] = useState(new Date());
    const [endpointStatuses, setEndpointStatuses] = useState({});
    const [testingEndpoints, setTestingEndpoints] = useState(false);

    const endpoints = [
        { name: '/health', path: '/health' },
        { name: '/tasks/list', path: '/tasks/list' },
        { name: '/calendar/today', path: '/calendar/today' },
        { name: '/tools/list', path: '/tools/list' },
        { name: '/gmail/unread', path: '/gmail/unread' },
    ];

    const testAllEndpoints = async () => {
        setTestingEndpoints(true);
        const statuses = {};
        for (const endpoint of endpoints) {
            statuses[endpoint.path] = await testEndpoint(endpoint.path);
        }
        setEndpointStatuses(statuses);
        setTestingEndpoints(false);
        setLastUpdate(new Date());
    };

    useEffect(() => {
        testAllEndpoints();
        const interval = setInterval(testAllEndpoints, 60000);
        return () => clearInterval(interval);
    }, []);

    const handleRefresh = () => {
        refetchHealth();
        testAllEndpoints();
    };

    const isOnline = !healthLoading && health?.status === 'ok';

    return (
        <div className="p-8">
            {/* Header */}
            <div className="flex items-center justify-between mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-slate-800">System Monitor</h1>
                    <p className="text-slate-500 mt-1">Real-time health and performance monitoring</p>
                </div>
                <div className="flex items-center gap-4">
                    <span className="text-sm text-slate-500">
                        Last updated: {lastUpdate.toLocaleTimeString()}
                    </span>
                    <button
                        onClick={handleRefresh}
                        disabled={testingEndpoints}
                        className="flex items-center gap-2 px-4 py-2 rounded-xl bg-violet-600 hover:bg-violet-700 text-white font-medium transition-colors disabled:opacity-50"
                    >
                        <RefreshCw className={`w-4 h-4 ${testingEndpoints ? 'animate-spin' : ''}`} />
                        Refresh
                    </button>
                </div>
            </div>

            {/* Main Status Card */}
            <Card className="mb-8 bg-gradient-to-br from-violet-600 to-indigo-700 text-white">
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-6">
                        <div className="p-4 rounded-2xl bg-white/20">
                            <Server className="w-8 h-8" />
                        </div>
                        <div>
                            <h2 className="text-2xl font-bold">Vyana Backend</h2>
                            <p className="text-white/70">FastAPI Server • Python 3.11</p>
                            {backendInfo?.mcp_endpoint && (
                                <p className="text-white/60 text-sm mt-1">MCP: {backendInfo.mcp_endpoint}</p>
                            )}
                        </div>
                    </div>
                    <div className={`flex items-center gap-3 px-4 py-2 rounded-xl ${healthLoading ? 'bg-yellow-500/30' :
                            isOnline ? 'bg-green-500/30' : 'bg-red-500/30'
                        }`}>
                        {healthLoading ? (
                            <Loader2 className="w-5 h-5 animate-spin" />
                        ) : isOnline ? (
                            <CheckCircle className="w-5 h-5" />
                        ) : (
                            <XCircle className="w-5 h-5" />
                        )}
                        <span className="font-semibold">
                            {healthLoading ? 'Checking...' : isOnline ? 'All Systems Operational' : 'Connection Failed'}
                        </span>
                    </div>
                </div>
            </Card>

            {/* System Metrics */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                <Card>
                    <div className="flex items-center gap-4 mb-4">
                        <div className="p-3 rounded-xl bg-violet-100">
                            <Wifi className="w-6 h-6 text-violet-600" />
                        </div>
                        <span className="text-slate-600 font-medium">Connection</span>
                    </div>
                    <p className="text-3xl font-bold text-slate-800">{isOnline ? 'Active' : 'Offline'}</p>
                    <p className="mt-2 text-sm text-slate-500">
                        {isOnline ? 'Backend responding normally' : 'Unable to reach backend'}
                    </p>
                </Card>

                <Card>
                    <div className="flex items-center gap-4 mb-4">
                        <div className="p-3 rounded-xl bg-blue-100">
                            <Cpu className="w-6 h-6 text-blue-600" />
                        </div>
                        <span className="text-slate-600 font-medium">API Version</span>
                    </div>
                    <p className="text-3xl font-bold text-slate-800">{health?.version || 'N/A'}</p>
                    <p className="mt-2 text-sm text-slate-500">Current backend version</p>
                </Card>

                <Card>
                    <div className="flex items-center gap-4 mb-4">
                        <div className="p-3 rounded-xl bg-green-100">
                            <Clock className="w-6 h-6 text-green-600" />
                        </div>
                        <span className="text-slate-600 font-medium">Status</span>
                    </div>
                    <p className="text-3xl font-bold text-slate-800">{health?.status?.toUpperCase() || 'N/A'}</p>
                    <p className="mt-2 text-sm text-slate-500">Health check status</p>
                </Card>
            </div>

            {/* Endpoints Status */}
            <Card>
                <h2 className="text-lg font-semibold text-slate-800 mb-6 flex items-center gap-2">
                    <Wifi className="w-5 h-5 text-violet-600" />
                    API Endpoints
                    {testingEndpoints && <Loader2 className="w-4 h-4 animate-spin text-violet-600 ml-2" />}
                </h2>
                <div className="space-y-3">
                    {endpoints.map((endpoint) => {
                        const status = endpointStatuses[endpoint.path];
                        return (
                            <div
                                key={endpoint.name}
                                className="flex items-center justify-between p-4 rounded-xl bg-slate-50 hover:bg-slate-100 transition-colors"
                            >
                                <div className="flex items-center gap-4">
                                    {!status ? (
                                        <Loader2 className="w-5 h-5 text-slate-400 animate-spin" />
                                    ) : status.status === 'online' ? (
                                        <CheckCircle className="w-5 h-5 text-green-500" />
                                    ) : status.status === 'timeout' ? (
                                        <AlertCircle className="w-5 h-5 text-yellow-500" />
                                    ) : (
                                        <XCircle className="w-5 h-5 text-red-500" />
                                    )}
                                    <span className="font-mono text-slate-700">{endpoint.name}</span>
                                </div>
                                <div className="flex items-center gap-4">
                                    <span className="text-sm text-slate-500 font-mono">
                                        {status?.latency || '-'}
                                    </span>
                                    <StatusBadge status={status?.status || 'loading'} />
                                </div>
                            </div>
                        );
                    })}
                </div>
            </Card>
        </div>
    );
}
