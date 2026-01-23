import React, { createContext, useContext, useEffect, useState } from 'react'
import type { User, Session } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'

// Demo mode - enabled when Supabase is not properly configured
const DEMO_MODE = !import.meta.env.VITE_SUPABASE_URL ||
    import.meta.env.VITE_SUPABASE_URL === 'https://placeholder.supabase.co' ||
    import.meta.env.VITE_SUPABASE_URL.includes('your_project')

const DEMO_USER: User = {
    id: 'demo-user-id',
    email: 'demo@vyana.ai',
    user_metadata: {
        full_name: 'Demo User',
        avatar_url: '',
    },
    app_metadata: {},
    aud: 'authenticated',
    created_at: new Date().toISOString(),
} as User

interface AuthContextType {
    user: User | null
    session: Session | null
    loading: boolean
    isDemoMode: boolean
    signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: React.ReactNode }) {
    const [user, setUser] = useState<User | null>(DEMO_MODE ? DEMO_USER : null)
    const [session, setSession] = useState<Session | null>(null)
    const [loading, setLoading] = useState(!DEMO_MODE)

    useEffect(() => {
        if (DEMO_MODE) {
            console.log('🎭 Running in Demo Mode - Supabase not configured')
            setUser(DEMO_USER)
            setLoading(false)
            return
        }

        // Get initial session
        supabase.auth.getSession().then(({ data: { session } }) => {
            setSession(session)
            setUser(session?.user ?? null)
            setLoading(false)
        })

        // Listen for auth changes
        const {
            data: { subscription },
        } = supabase.auth.onAuthStateChange((_event, session) => {
            setSession(session)
            setUser(session?.user ?? null)
            setLoading(false)
        })

        return () => subscription.unsubscribe()
    }, [])

    const signOut = async () => {
        if (!DEMO_MODE) {
            await supabase.auth.signOut()
        }
        // Always clear user state on signOut (even in Demo Mode)
        setUser(null)
        setSession(null)
    }

    return (
        <AuthContext.Provider value={{ user, session, loading, isDemoMode: DEMO_MODE, signOut }}>
            {children}
        </AuthContext.Provider>
    )
}

export function useAuth() {
    const context = useContext(AuthContext)
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider')
    }
    return context
}
