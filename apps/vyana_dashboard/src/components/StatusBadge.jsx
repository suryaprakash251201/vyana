export function StatusBadge({ status, label }) {
    const statusStyles = {
        online: 'bg-green-500/20 text-green-400 border-green-500/30',
        offline: 'bg-red-500/20 text-red-400 border-red-500/30',
        warning: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
        loading: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
    };

    const dotStyles = {
        online: 'bg-green-400',
        offline: 'bg-red-400',
        warning: 'bg-yellow-400',
        loading: 'bg-blue-400 animate-pulse',
    };

    return (
        <span
            className={`
        inline-flex items-center gap-2 px-3 py-1.5 rounded-full 
        text-sm font-medium border
        ${statusStyles[status] || statusStyles.loading}
      `}
        >
            <span className={`w-2 h-2 rounded-full ${dotStyles[status] || dotStyles.loading}`} />
            {label || status}
        </span>
    );
}
