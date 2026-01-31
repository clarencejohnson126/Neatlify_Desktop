
import React, { useEffect, useState } from 'react';
import { translations, Language } from './translations';

const SuccessPage: React.FC = () => {
  const [sessionId, setSessionId] = useState<string>('');
  const [copied, setCopied] = useState(false);
  const [lang] = useState<Language>(() => {
    const saved = localStorage.getItem('neatlify_lang');
    return (saved as Language) || 'EN';
  });

  const t = translations[lang].success;

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const sid = params.get('session_id') || 'CS_MOCK_12345';
    setSessionId(sid);

    // Attempt to open the app
    const redirectUrl = `neatlify://activate?session_id=${sid}`;
    window.location.href = redirectUrl;
  }, []);

  const copyToClipboard = () => {
    navigator.clipboard.writeText(sessionId);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-[#FAFAF8] paper-texture">
      <div className="max-w-xl w-full bg-white sketch-border p-12 text-center cartoon-shadow">
        <div className="w-20 h-20 bg-[#29AB87] rounded-full mx-auto mb-8 flex items-center justify-center sketch-border cartoon-shadow">
          <span className="text-white text-4xl">✓</span>
        </div>
        
        <h1 className="text-4xl font-bold mb-4">{t.title}</h1>
        <p className="text-xl text-charcoal opacity-70 mb-8">{t.subtitle}</p>

        <div className="animate-spin w-10 h-10 border-4 border-[#29AB87] border-t-transparent rounded-full mx-auto mb-12"></div>

        <div className="text-left bg-[#FAFAF8] p-6 sketch-border border-dashed">
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

        <button 
          onClick={() => window.location.hash = '/'}
          className="mt-12 text-[#29AB87] font-bold underline"
        >
          Back to Home
        </button>
      </div>
    </div>
  );
};

export default SuccessPage;
