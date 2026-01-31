
import React, { useState, useEffect } from 'react';
import { Language } from './translations';

const ImpressumPage: React.FC = () => {
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
            {lang === 'EN' ? 'Legal Notice (Impressum)' : 'Impressum'}
          </h1>

          <div className="space-y-8 text-lg opacity-90">
            {/* Legal requirement notice */}
            <p className="text-sm opacity-60">
              {lang === 'EN'
                ? 'Information according to § 5 TMG (German Telemedia Act)'
                : 'Angaben gemäß § 5 TMG'}
            </p>

            {/* Company Info */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Company Information' : 'Anbieter'}
              </h2>
              <div className="space-y-1">
                <p className="font-bold">Clarence Johnson</p>
                <p>Johnson Services</p>
                <p>George-Washington-Str. 219</p>
                <p>68309 Mannheim</p>
                <p>{lang === 'EN' ? 'Germany' : 'Deutschland'}</p>
              </div>
            </section>

            {/* Contact */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Contact' : 'Kontakt'}
              </h2>
              <div className="space-y-1">
                <p>E-Mail: <a href="mailto:hello@neatlify.app" className="text-[#FFD93D] hover:underline">hello@neatlify.app</a></p>
              </div>
            </section>

            {/* Tax Info */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Tax Information' : 'Steuerliche Angaben'}
              </h2>
              <div className="space-y-1">
                <p>{lang === 'EN' ? 'Small business according to § 19 UStG' : 'Kleinunternehmer gemäß § 19 UStG'}</p>
                <p>{lang === 'EN' ? 'VAT ID' : 'Umsatzsteuer-ID'}: DE452125652</p>
                <p>{lang === 'EN' ? 'Tax Office' : 'Zuständiges Finanzamt'}: Finanzamt Mannheim-Neckarstadt</p>
              </div>
            </section>

            {/* Disclaimer */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Disclaimer' : 'Haftungsausschluss'}
              </h2>
              <p className="leading-relaxed">
                {lang === 'EN'
                  ? 'The contents of this website are created with the greatest possible care. However, I assume no liability for the accuracy, completeness, and timeliness of the content provided.'
                  : 'Die Inhalte dieser Website werden mit größtmöglicher Sorgfalt erstellt. Ich übernehme jedoch keine Gewähr für die Richtigkeit, Vollständigkeit und Aktualität der bereitgestellten Inhalte.'}
              </p>
            </section>

            {/* Liability for Content */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Liability for Content' : 'Haftung für Inhalte'}
              </h2>
              <p className="leading-relaxed">
                {lang === 'EN'
                  ? 'As a service provider, I am responsible for my own content on these pages according to general laws. However, I am not obligated to monitor transmitted or stored third-party information or to investigate circumstances that indicate illegal activity.'
                  : 'Als Diensteanbieter bin ich für eigene Inhalte auf diesen Seiten nach den allgemeinen Gesetzen verantwortlich. Ich bin jedoch nicht verpflichtet, übermittelte oder gespeicherte fremde Informationen zu überwachen oder nach Umständen zu forschen, die auf eine rechtswidrige Tätigkeit hinweisen.'}
              </p>
            </section>

            {/* Liability for Links */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Liability for Links' : 'Haftung für Links'}
              </h2>
              <p className="leading-relaxed">
                {lang === 'EN'
                  ? 'This website contains links to external third-party websites over whose content I have no influence. Therefore, I cannot assume any liability for this external content. The respective provider or operator of the pages is always responsible for the content of the linked pages.'
                  : 'Diese Website enthält Links zu externen Websites Dritter, auf deren Inhalte ich keinen Einfluss habe. Deshalb kann ich für diese fremden Inhalte auch keine Gewähr übernehmen. Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter oder Betreiber der Seiten verantwortlich.'}
              </p>
            </section>

            {/* Copyright */}
            <section>
              <h2 className="text-2xl font-bold mb-4 text-[#29AB87]">
                {lang === 'EN' ? 'Copyright' : 'Urheberrecht'}
              </h2>
              <p className="leading-relaxed">
                {lang === 'EN'
                  ? 'The content and works created by the site operator on these pages are subject to German copyright law. Duplication, processing, distribution, and any kind of exploitation outside the limits of copyright law require the written consent of the respective author or creator.'
                  : 'Die durch den Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen dem deutschen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der schriftlichen Zustimmung des jeweiligen Autors bzw. Erstellers.'}
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

export default ImpressumPage;
