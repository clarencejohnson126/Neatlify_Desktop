
import React, { useState, useEffect } from 'react';
import { Language } from './translations';

const PrivacyPage: React.FC = () => {
  const [lang, setLang] = useState<Language>(() => {
    const saved = localStorage.getItem('neatlify_lang');
    return (saved as Language) || 'EN';
  });

  useEffect(() => {
    localStorage.setItem('neatlify_lang', lang);
  }, [lang]);

  const toggleLang = () => setLang(prev => prev === 'EN' ? 'DE' : 'EN');

  return (
    <div className="min-h-screen bg-[#2D3436] text-white">
      {/* Navbar */}
      <nav className="fixed top-0 left-0 right-0 bg-[#FAFAF8] bg-opacity-95 backdrop-blur-md z-50 border-b-4 border-[#2D3436] py-4">
        <div className="max-w-6xl mx-auto px-6 flex justify-between items-center">
          <a href="#/" className="flex items-center gap-3 cursor-pointer group">
            <div className="w-12 h-12 bg-[#29AB87] sketch-border flex items-center justify-center cartoon-shadow group-hover:scale-110 transition-all">
              <span className="text-white font-bold text-2xl">N</span>
            </div>
            <span className="text-3xl font-bold text-[#2D3436] tracking-tight">Neatlify</span>
          </a>

          <div className="flex items-center gap-3">
            <button
              onClick={toggleLang}
              className="sketch-border px-4 py-2 text-sm font-bold bg-[#FFD93D] cartoon-shadow-hover transition-all text-[#2D3436]"
            >
              {lang === 'EN' ? 'EN | DE' : 'DE | EN'}
            </button>
            <a
              href="#/"
              className="sketch-border px-4 py-2 text-sm font-bold bg-[#29AB87] text-white cartoon-shadow-hover transition-all"
            >
              {lang === 'EN' ? 'Back to Home' : 'Zur Startseite'}
            </a>
          </div>
        </div>
      </nav>

      {/* Content */}
      <div className="pt-32 pb-20 px-6">
        <div className="max-w-3xl mx-auto">
          <h1 className="text-4xl md:text-5xl font-black mb-8">
            {lang === 'EN' ? 'Privacy Policy' : 'Datenschutzerklärung'}
          </h1>

          <div className="space-y-8 text-lg opacity-90">
            {/* Introduction */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Overview' : 'Übersicht'}
              </h2>
              <p className="leading-relaxed">
                {lang === 'EN'
                  ? 'Your privacy is important to us. This privacy policy explains what personal data Neatlify collects and how we use it.'
                  : 'Ihre Privatsphäre ist uns wichtig. Diese Datenschutzerklärung erläutert, welche personenbezogenen Daten Neatlify erhebt und wie wir diese verwenden.'}
              </p>
            </section>

            {/* Responsible Party */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Responsible Party' : 'Verantwortlicher'}
              </h2>
              <div className="space-y-1">
                <p className="font-bold">Clarence Johnson</p>
                <p>Johnson Services</p>
                <p>George-Washington-Str. 219</p>
                <p>68309 Mannheim</p>
                <p>{lang === 'EN' ? 'Germany' : 'Deutschland'}</p>
                <p className="mt-2">E-Mail: <a href="mailto:hello@neatlify.app" className="text-[#FFD93D] hover:underline">hello@neatlify.app</a></p>
              </div>
            </section>

            {/* Data Collection */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Data We Collect' : 'Welche Daten wir erheben'}
              </h2>
              <div className="space-y-4">
                <div>
                  <h3 className="font-bold text-[#FFD93D] mb-2">{lang === 'EN' ? 'Account Information' : 'Kontoinformationen'}</h3>
                  <p className="leading-relaxed">
                    {lang === 'EN'
                      ? 'When you create an account, we collect your email address and name. This is used to manage your account and credits.'
                      : 'Wenn Sie ein Konto erstellen, erheben wir Ihre E-Mail-Adresse und Ihren Namen. Diese werden zur Verwaltung Ihres Kontos und Ihrer Credits verwendet.'}
                  </p>
                </div>
                <div>
                  <h3 className="font-bold text-[#FFD93D] mb-2">{lang === 'EN' ? 'Payment Information' : 'Zahlungsinformationen'}</h3>
                  <p className="leading-relaxed">
                    {lang === 'EN'
                      ? 'Payment processing is handled by Stripe. We do not store your credit card details. Stripe\'s privacy policy applies to payment data.'
                      : 'Die Zahlungsabwicklung erfolgt über Stripe. Wir speichern keine Kreditkartendaten. Für Zahlungsdaten gilt die Datenschutzerklärung von Stripe.'}
                  </p>
                </div>
                <div>
                  <h3 className="font-bold text-[#FFD93D] mb-2">{lang === 'EN' ? 'File Descriptions' : 'Dateibeschreibungen'}</h3>
                  <p className="leading-relaxed">
                    {lang === 'EN'
                      ? 'When you use Neatlify, we send text descriptions of your files to our AI service for analysis. Your actual files never leave your Mac. Only text descriptions are transmitted.'
                      : 'Wenn Sie Neatlify verwenden, senden wir Textbeschreibungen Ihrer Dateien an unseren KI-Dienst zur Analyse. Ihre tatsächlichen Dateien verlassen niemals Ihren Mac. Es werden nur Textbeschreibungen übertragen.'}
                  </p>
                </div>
              </div>
            </section>

            {/* Data Storage */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Data Storage' : 'Datenspeicherung'}
              </h2>
              <p className="leading-relaxed">
                {lang === 'EN'
                  ? 'Your account data is stored securely on Supabase servers in the EU. File descriptions are processed but not permanently stored. We retain account data as long as your account is active.'
                  : 'Ihre Kontodaten werden sicher auf Supabase-Servern in der EU gespeichert. Dateibeschreibungen werden verarbeitet, aber nicht dauerhaft gespeichert. Wir bewahren Kontodaten auf, solange Ihr Konto aktiv ist.'}
              </p>
            </section>

            {/* Your Rights */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Your Rights (GDPR)' : 'Ihre Rechte (DSGVO)'}
              </h2>
              <ul className="list-disc list-inside space-y-2">
                <li>{lang === 'EN' ? 'Right to access your personal data' : 'Recht auf Auskunft über Ihre personenbezogenen Daten'}</li>
                <li>{lang === 'EN' ? 'Right to rectification of inaccurate data' : 'Recht auf Berichtigung unrichtiger Daten'}</li>
                <li>{lang === 'EN' ? 'Right to erasure ("right to be forgotten")' : 'Recht auf Löschung ("Recht auf Vergessenwerden")'}</li>
                <li>{lang === 'EN' ? 'Right to restriction of processing' : 'Recht auf Einschränkung der Verarbeitung'}</li>
                <li>{lang === 'EN' ? 'Right to data portability' : 'Recht auf Datenübertragbarkeit'}</li>
                <li>{lang === 'EN' ? 'Right to object to processing' : 'Widerspruchsrecht gegen die Verarbeitung'}</li>
              </ul>
              <p className="mt-4 leading-relaxed">
                {lang === 'EN'
                  ? 'To exercise these rights, contact us at hello@neatlify.app'
                  : 'Um diese Rechte auszuüben, kontaktieren Sie uns unter hello@neatlify.app'}
              </p>
            </section>

            {/* Cookies */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Cookies' : 'Cookies'}
              </h2>
              <p className="leading-relaxed">
                {lang === 'EN'
                  ? 'We use essential cookies only to maintain your session and language preferences. We do not use tracking or advertising cookies.'
                  : 'Wir verwenden nur essentielle Cookies zur Aufrechterhaltung Ihrer Sitzung und Spracheinstellungen. Wir verwenden keine Tracking- oder Werbe-Cookies.'}
              </p>
            </section>

            {/* Third Party Services */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Third-Party Services' : 'Drittanbieter-Dienste'}
              </h2>
              <ul className="list-disc list-inside space-y-2">
                <li><strong>Supabase</strong> - {lang === 'EN' ? 'Authentication and database (EU servers)' : 'Authentifizierung und Datenbank (EU-Server)'}</li>
                <li><strong>Stripe</strong> - {lang === 'EN' ? 'Payment processing' : 'Zahlungsabwicklung'}</li>
                <li><strong>Anthropic (Claude)</strong> - {lang === 'EN' ? 'AI analysis of file descriptions' : 'KI-Analyse von Dateibeschreibungen'}</li>
              </ul>
            </section>

            {/* Contact */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Contact' : 'Kontakt'}
              </h2>
              <p className="leading-relaxed">
                {lang === 'EN'
                  ? 'For any privacy-related questions, please contact us at:'
                  : 'Bei Fragen zum Datenschutz kontaktieren Sie uns unter:'}
              </p>
              <p className="mt-2">
                <a href="mailto:hello@neatlify.app" className="text-[#FFD93D] hover:underline">hello@neatlify.app</a>
              </p>
            </section>

            {/* Last Updated */}
            <p className="text-sm opacity-60 pt-8 border-t border-white border-opacity-20">
              {lang === 'EN' ? 'Last updated: January 2026' : 'Zuletzt aktualisiert: Januar 2026'}
            </p>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="py-8 px-6 border-t-4 border-[#29AB87]">
        <div className="max-w-6xl mx-auto text-center text-sm opacity-60">
          © 2026 Neatlify. {lang === 'EN' ? 'All rights reserved.' : 'Alle Rechte vorbehalten.'}
        </div>
      </footer>
    </div>
  );
};

export default PrivacyPage;
