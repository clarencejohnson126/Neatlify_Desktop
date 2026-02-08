import React, { createContext, useContext, useEffect, useState } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase, Profile } from '../lib/supabase';
import { launchDesktopAppWithAuth } from '../lib/authTokenHandler';

interface AuthContextType {
  user: User | null;
  profile: Profile | null;
  session: Session | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<{ error: Error | null }>;
  signUp: (email: string, password: string, fullName?: string) => Promise<{ error: Error | null }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<{ error: Error | null }>;
  launchDesktopApp: () => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  // Fetch user profile
  const fetchProfile = async (userId: string) => {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      console.error('Error fetching profile:', error);
      return null;
    }
    return data as Profile;
  };

  useEffect(() => {
    let isMounted = true;

    const updateAuthState = (nextSession: Session | null) => {
      if (!isMounted) return;

      setSession(nextSession);
      const nextUser = nextSession?.user ?? null;
      setUser(nextUser);
      setLoading(false);

      if (!nextUser) {
        setProfile(null);
      }
    };

    supabase.auth.getSession()
      .then(({ data: { session } }) => {
        updateAuthState(session);
      })
      .catch((error) => {
        console.error('Error getting session:', error);
        if (isMounted) {
          setLoading(false);
        }
      });

    // Keep callback synchronous; avoid await/Supabase calls directly inside onAuthStateChange.
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      updateAuthState(nextSession);
    });

    return () => {
      isMounted = false;
      subscription.unsubscribe();
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    if (!user) {
      setProfile(null);
      return;
    }

    fetchProfile(user.id).then((nextProfile) => {
      if (!cancelled) {
        setProfile(nextProfile);
      }
    });

    return () => {
      cancelled = true;
    };
  }, [user?.id]);

  const signIn = async (email: string, password: string) => {
    try {
      console.log('Attempting sign in for:', email);
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      console.log('Sign in result:', { hasData: !!data, hasError: !!error });
      return { error: error as Error | null };
    } catch (err) {
      console.error('Sign in exception:', err);
      return { error: err as Error };
    }
  };

  const signUp = async (email: string, password: string, fullName?: string) => {
    try {
      console.log('Attempting sign up for:', email);
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          emailRedirectTo: 'https://www.neatlify.app/#/',
          data: {
            full_name: fullName || '',
          },
        },
      });
      console.log('Sign up result:', { hasData: !!data, hasError: !!error });
      return { error: error as Error | null };
    } catch (err) {
      console.error('Sign up exception:', err);
      return { error: err as Error };
    }
  };

  const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) {
      throw error;
    }

    // Keep UI in sync even if the auth-state event is delayed/missed.
    setSession(null);
    setUser(null);
    setProfile(null);
    setLoading(false);
  };

  const resetPassword = async (email: string) => {
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/#/reset-password`,
    });
    return { error: error as Error | null };
  };

  const launchDesktopApp = () => {
    console.log('Attempting to launch desktop app with current session...');
    return launchDesktopAppWithAuth(session, user);
  };

  const value = {
    user,
    profile,
    session,
    loading,
    signIn,
    signUp,
    signOut,
    resetPassword,
    launchDesktopApp,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
