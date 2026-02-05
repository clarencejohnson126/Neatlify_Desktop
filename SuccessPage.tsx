import React, { useEffect, useState } from 'react';
import { useAuth } from './contexts/AuthContext';
import { translations, Language } from './translations';
import { getSessionTokens, validateEmail, validateJWT } from './lib/authTokenHandler';

const SuccessPage: React.FC = () => {
  const { user, session } = useAuth();
  const [sessionId, setSessionId] = useState<string>('');
  const [copied, setCopied] = useState(false);
  const [status, setStatus] = useState<'verifying' | 'success' | 'error'>('verifying');
  const [creditsAdded, setCreditsAdded] = useState(0);
  const [errorMessage, setErrorMessage] = useState('');
  const [lang] = useState<Language>(() => {
    const saved = localStorage.getItem('neatlify_lang');
    return (saved as Language) || 'EN';
  });

  const t = translations[lang].success;

  useEffect(() => {
    // Get session_id from URL - handle both hash and query params
    let sid = '';

    // Try hash params first (for hash routing: #/success?session_id=xxx)
    const hashParams = new URLSearchParams(window.location.hash.split('?')[1] || '');
    sid = hashParams.get('session_id') || '';

    // Fallback to regular query params
    if (!sid) {
      const params = new URLSearchParams(window.location.search);
      sid = params.get('session_id') || '';
    }

    if (sid) {
      setSessionId(sid);
      verifyPayment(sid);

      // Attempt to open the desktop app with auth tokens for credit sync
      // Priority: Send auth tokens (auth-callback) so app can authenticate
      // Fallback: Send checkout/success for payment verification
      if (session?.access_token && user?.email) {
        // We have tokens - use auth-callback format for proper authentication
        const tokens = getSessionTokens(session, user);
        if (tokens && validateJWT(tokens.accessToken) && validateEmail(user.email)) {
          const authDeepLink = `neatlify://auth-callback?access_token=${tokens.accessToken}&refresh_token=${tokens.refreshToken}&user_email=${encodeURIComponent(user.email)}&exp=${tokens.expiresAt}&iat=${tokens.issuedAt}`;
          console.log('Sending auth-callback deep link for payment success');
          setTimeout(() => {
            window.location.href = authDeepLink;
          }, 1000);
          return;
        }
      }

      // Fallback: Send checkout/success with session_id if no tokens available
      const redirectUrl = `neatlify://checkout/success?session_id=${sid}`;
      setTimeout(() => {
        window.location.href = redirectUrl;
      }, 1000);
    } else {
      setStatus('error');
      setErrorMessage('No payment session found in URL.');
    }
  }, []);

  const verifyPayment = async (sid: string) => {
    try {
      const response = await fetch('https://nlvlwrhayrvberdyjgjx.supabase.co/functions/v1/verify-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id: sid,
          user_email: user?.email,
        }),
      });

      const data = await response.json();

      if (response.ok && data.success) {
        setStatus('success');
        setCreditsAdded(data.credits_added);
      } else {
        // Don't show error if already processed
        if (data.already_processed) {
          setStatus('success');
          setCreditsAdded(data.credits_added || 0);
        } else {
          setStatus('error');
          setErrorMessage(data.error || 'Failed to verify payment.');
        }
      }
    } catch (error) {
      console.error('Payment verification error:', error);
      setStatus('error');
      setErrorMessage('Failed to connect to payment server.');
    }
  };

  const copyToClipboard = () => {
    navigator.clipboard.writeText(sessionId);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const getAppDeepLink = (): string => {
    // Generate the best deep link based on available auth data
    if (session?.access_token && user?.email) {
      const tokens = getSessionTokens(session, user);
      if (tokens && validateJWT(tokens.accessToken) && validateEmail(user.email)) {
        // Send auth tokens for proper authentication
        return `neatlify://auth-callback?access_token=${tokens.accessToken}&refresh_token=${tokens.refreshToken}&user_email=${encodeURIComponent(user.email)}&exp=${tokens.expiresAt}&iat=${tokens.issuedAt}`;
      }
    }
    // Fallback to payment verification
    return `neatlify://checkout/success?session_id=${sessionId}`;
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-[#FAFAF8] paper-texture">
      <div className="max-w-xl w-full bg-white sketch-border p-12 text-center cartoon-shadow">
        {/* Status Icon */}
        <div className={`w-20 h-20 rounded-full mx-auto mb-8 flex items-center justify-center sketch-border cartoon-shadow ${
          status === 'verifying' ? 'bg-[#FFD93D]' :
          status === 'success' ? 'bg-[#29AB87]' : 'bg-[#FF6B6B]'
        }`}>
          {status === 'verifying' && (
            <div className="animate-spin w-8 h-8 border-4 border-white border-t-transparent rounded-full"></div>
          )}
          {status === 'success' && (
            <span className="text-white text-4xl">✓</span>
          )}
          {status === 'error' && (
            <span className="text-white text-4xl">!</span>
          )}
        </div>

        {status === 'verifying' && (
          <>
            <h1 className="text-4xl font-bold mb-4">Processing Payment...</h1>
            <p className="text-xl text-charcoal opacity-70 mb-8">Adding credits to your account</p>
          </>
        )}

        {status === 'success' && (
          <>
            <h1 className="text-4xl font-bold mb-4 text-[#29AB87]">{t.title}</h1>
            <p className="text-xl text-charcoal opacity-70 mb-4">{t.subtitle}</p>

            {creditsAdded > 0 && (
              <div className="my-6 p-4 bg-[#29AB87] text-white sketch-border inline-block">
                <div className="text-5xl font-black">+{creditsAdded}</div>
                <div className="text-sm opacity-80">Credits Added</div>
              </div>
            )}
          </>
        )}

        {status === 'error' && (
          <>
            <h1 className="text-4xl font-bold mb-4 text-[#FF6B6B]">Verification Issue</h1>
            <p className="text-xl text-charcoal opacity-70 mb-4">{errorMessage}</p>
            <p className="text-sm text-charcoal opacity-50 mb-8">
              If you were charged, please contact support with your payment receipt.
            </p>
          </>
        )}

        {status !== 'verifying' && sessionId && (
          <div className="text-left bg-[#FAFAF8] p-6 sketch-border border-dashed mt-8">
            <h2 className="font-bold mb-4">{t.instructions}</h2>
            <ul className="space-y-2 text-sm text-charcoal opacity-80 mb-6">
              <li>{t.step1}</li>
              <li>{t.step2}</li>
              <li>{t.step3}</li>
              <li>{t.step4}</li>
            </ul>

            <div className="flex flex-col gap-2">
              <div className="bg-white sketch-border p-3 font-mono text-xs break-all border-[#FFD93D]">
                {sessionId}
              </div>
              <button
                onClick={copyToClipboard}
                className="bg-[#FFD93D] px-6 py-2 font-bold sketch-border cartoon-shadow-hover transition-all text-sm"
              >
                {copied ? t.copied : t.copy}
              </button>
            </div>
          </div>
        )}

        {/* Open App Button - Primary Action */}
        {status === 'success' && sessionId && (
          <div className="mt-8 mb-6">
            <a
              href={getAppDeepLink()}
              className="inline-block px-8 py-4 bg-[#29AB87] text-white text-xl font-bold sketch-border cartoon-shadow-hover transition-all"
            >
              ✨ Open Neatlify App
            </a>
            <p className="mt-4 text-sm text-charcoal opacity-60">
              Your credits are ready! Click above to return to the app and start organizing.
            </p>
          </div>
        )}

        <div className="mt-4 flex gap-4 justify-center">
          <button
            onClick={() => window.location.hash = '/'}
            className="px-6 py-3 bg-[#2D3436] text-white font-bold sketch-border cartoon-shadow-hover transition-all"
          >
            Back to Home
          </button>
          <button
            onClick={() => window.location.hash = '/account'}
            className="px-6 py-3 bg-white text-charcoal font-bold sketch-border cartoon-shadow-hover transition-all"
          >
            My Account
          </button>
        </div>
      </div>
    </div>
  );
};

export default SuccessPage;
