import React, { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialMode?: 'login' | 'signup';
}

const AuthModal: React.FC<AuthModalProps> = ({ isOpen, onClose, initialMode = 'login' }) => {
  const [mode, setMode] = useState<'login' | 'signup' | 'forgot'>(initialMode);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  const { signIn, signUp, resetPassword } = useAuth();

  const getReadableError = (errorMessage: string): string => {
    if (!errorMessage) return 'An error occurred. Please try again.';

    // Rate limiting errors
    if (errorMessage.includes('429') || errorMessage.includes('rate_limit') || errorMessage.includes('after 6 seconds')) {
      return '⏱️ Too many attempts. Please wait 10 minutes before trying again.';
    }

    // Invalid credentials
    if (errorMessage.includes('Invalid login credentials') || errorMessage.includes('invalid_credentials')) {
      return '❌ Incorrect email or password. Please try again.';
    }

    // Invalid email
    if (errorMessage.includes('invalid email') || errorMessage.includes('Email address is invalid')) {
      return '❌ The email address is invalid. Please check the spelling.';
    }

    // User already exists
    if (errorMessage.includes('User already registered') || errorMessage.includes('already exists')) {
      return '📧 This email is already registered. Try signing in instead!';
    }

    // Email confirmation required
    if (errorMessage.includes('Email not confirmed') || errorMessage.includes('email_not_confirmed')) {
      return '📬 Please confirm your email first. Check your inbox for the confirmation link.';
    }

    // Network/connection errors
    if (errorMessage.includes('network') || errorMessage.includes('Network')) {
      return '🌐 Network error. Please check your connection and try again.';
    }

    // Default: return the error message itself if we don't recognize it
    return errorMessage;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setMessage('');
    setLoading(true);
    console.log('Auth modal: handleSubmit called, mode:', mode);

    try {
      if (mode === 'login') {
        console.log('Auth modal: calling signIn...');
        const { error } = await signIn(email, password);
        console.log('Auth modal: signIn returned, error:', error);
        if (error) {
          setError(getReadableError(error.message));
        } else {
          console.log('Auth modal: success, calling onClose');
          onClose();
          resetForm();
        }
      } else if (mode === 'signup') {
        const { error } = await signUp(email, password, fullName);
        if (error) {
          setError(getReadableError(error.message));
        } else {
          setMessage('✅ Check your email for the confirmation link!');
        }
      } else if (mode === 'forgot') {
        const { error } = await resetPassword(email);
        if (error) {
          setError(getReadableError(error.message));
        } else {
          setMessage('✅ Check your email for the password reset link!');
        }
      }
    } catch (err) {
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setEmail('');
    setPassword('');
    setFullName('');
    setError('');
    setMessage('');
  };

  const switchMode = (newMode: 'login' | 'signup' | 'forgot') => {
    setMode(newMode);
    setError('');
    setMessage('');
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-[#2D3436] bg-opacity-80 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="relative bg-white sketch-border cartoon-shadow p-8 w-full max-w-md mx-4 animate-bounce-in">
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 w-8 h-8 flex items-center justify-center text-2xl font-bold text-[#2D3436] hover:text-[#FF6B6B] transition-colors"
        >
          x
        </button>

        {/* Logo */}
        <div className="flex items-center justify-center gap-3 mb-6">
          <div className="w-10 h-10 bg-[#29AB87] sketch-border flex items-center justify-center">
            <span className="text-white font-bold text-xl">N</span>
          </div>
          <span className="text-2xl font-bold text-[#2D3436]">Neatlify</span>
        </div>

        {/* Title */}
        <h2 className="text-2xl font-black text-center mb-6">
          {mode === 'login' && 'Welcome Back!'}
          {mode === 'signup' && 'Create Account'}
          {mode === 'forgot' && 'Reset Password'}
        </h2>

        {/* Error/Message */}
        {error && (
          <div className="bg-[#FF6B6B] bg-opacity-10 text-[#FF6B6B] px-4 py-3 rounded-lg mb-4 text-sm font-bold sketch-border">
            {error}
          </div>
        )}
        {message && (
          <div className="bg-[#29AB87] bg-opacity-10 text-[#29AB87] px-4 py-3 rounded-lg mb-4 text-sm font-bold sketch-border">
            {message}
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {mode === 'signup' && (
            <div>
              <label className="block text-sm font-bold mb-2">Full Name</label>
              <input
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                className="w-full px-4 py-3 sketch-border focus:outline-none focus:ring-2 focus:ring-[#29AB87] font-medium"
                placeholder="John Doe"
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-bold mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 sketch-border focus:outline-none focus:ring-2 focus:ring-[#29AB87] font-medium"
              placeholder="you@example.com"
              required
            />
          </div>

          {mode !== 'forgot' && (
            <div>
              <label className="block text-sm font-bold mb-2">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 sketch-border focus:outline-none focus:ring-2 focus:ring-[#29AB87] font-medium"
                placeholder="••••••••"
                required
                minLength={6}
              />
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[#29AB87] text-white py-3 rounded-full font-bold sketch-border cartoon-shadow-hover transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? (
              <span className="inline-flex items-center gap-2">
                <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                Loading...
              </span>
            ) : (
              <>
                {mode === 'login' && 'Sign In'}
                {mode === 'signup' && 'Create Account'}
                {mode === 'forgot' && 'Send Reset Link'}
              </>
            )}
          </button>
        </form>

        {/* Mode switchers */}
        <div className="mt-6 text-center text-sm">
          {mode === 'login' && (
            <>
              <button
                onClick={() => switchMode('forgot')}
                className="text-[#29AB87] font-bold hover:underline"
              >
                Forgot password?
              </button>
              <div className="mt-3 text-[#2D3436] opacity-70">
                Don't have an account?{' '}
                <button
                  onClick={() => switchMode('signup')}
                  className="text-[#29AB87] font-bold hover:underline"
                >
                  Sign up
                </button>
              </div>
            </>
          )}
          {mode === 'signup' && (
            <div className="text-[#2D3436] opacity-70">
              Already have an account?{' '}
              <button
                onClick={() => switchMode('login')}
                className="text-[#29AB87] font-bold hover:underline"
              >
                Sign in
              </button>
            </div>
          )}
          {mode === 'forgot' && (
            <button
              onClick={() => switchMode('login')}
              className="text-[#29AB87] font-bold hover:underline"
            >
              Back to sign in
            </button>
          )}
        </div>
      </div>

      <style>{`
        @keyframes bounce-in {
          0% {
            opacity: 0;
            transform: scale(0.9) translateY(-20px);
          }
          100% {
            opacity: 1;
            transform: scale(1) translateY(0);
          }
        }
        .animate-bounce-in {
          animation: bounce-in 0.3s ease-out;
        }
      `}</style>
    </div>
  );
};

export default AuthModal;
