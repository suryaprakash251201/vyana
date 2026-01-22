export function Card({ children, className = '', noPadding = false }) {
    return (
        <div
            className={`
        bg-white rounded-3xl 
        shadow-[var(--shadow-card)] 
        ${noPadding ? '' : 'p-6'}
        ${className}
      `}
        >
            {children}
        </div>
    );
}

export function IconButton({ icon: Icon, onClick, className = '' }) {
    return (
        <button
            onClick={onClick}
            className={`p-2 rounded-xl hover:bg-slate-100 text-slate-500 transition-colors ${className}`}
        >
            <Icon className="w-5 h-5" />
        </button>
    );
}
