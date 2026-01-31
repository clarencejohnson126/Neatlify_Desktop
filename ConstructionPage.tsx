
import React, { useState, useEffect, useRef } from 'react';
import { translations, Language } from './translations';
import { useAuth } from './contexts/AuthContext';
import AuthModal from './components/AuthModal';
import UserMenu from './components/UserMenu';
import {
  HardHatIcon,
  BlueprintIcon,
  BuildingIcon,
  CameraIcon,
  TagIcon,
  ConstructionSiteIllustration,
  OrganizedFilesIllustration,
  RealEstateIllustration,
  ExcavatorIllustration,
  ConstructionWorkerIllustration,
  TradesIcon,
  QuoteIcon,
  FolderIcon,
  ChecklistIcon,
  DocumentStackIcon
} from './components/Illustrations';

// Scroll animation hook
const useScrollAnimation = () => {
  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
        }
      },
      { threshold: 0.1 }
    );

    if (ref.current) {
      observer.observe(ref.current);
    }

    return () => observer.disconnect();
  }, []);

  return { ref, isVisible };
};

// Animated Section Wrapper
const AnimatedSection = ({ children, className = '', delay = 0 }: { children: React.ReactNode; className?: string; delay?: number }) => {
  const { ref, isVisible } = useScrollAnimation();
  return (
    <div
      ref={ref}
      className={`fade-in-up ${isVisible ? 'visible' : ''} ${className}`}
      style={{ transitionDelay: `${delay}ms` }}
    >
      {children}
    </div>
  );
};

// Flip Card Component
const FlipCard = ({ front, back, className = '' }: { front: React.ReactNode; back: React.ReactNode; className?: string }) => {
  const [isFlipped, setIsFlipped] = useState(false);

  return (
    <div
      className={`flip-card cursor-pointer ${isFlipped ? 'flipped' : ''} ${className}`}
      onClick={() => setIsFlipped(!isFlipped)}
      style={{ height: '280px' }}
    >
      <div className="flip-card-inner" style={{ height: '100%' }}>
        <div className="flip-card-front bg-white sketch-border p-6 cartoon-shadow hover:bg-[#FAFAF8] transition-all overflow-hidden" style={{ height: '100%' }}>
          {front}
          <div className="absolute bottom-2 right-2 text-[10px] opacity-40 font-bold">Click to flip →</div>
        </div>
        <div className="flip-card-back bg-[#2D3436] text-white sketch-border p-6 overflow-hidden" style={{ height: '100%' }}>
          {back}
          <div className="absolute bottom-2 right-2 text-[10px] opacity-40">← Click to flip back</div>
        </div>
      </div>
    </div>
  );
};

const ConstructionPage: React.FC = () => {
  const [lang, setLang] = useState<Language>(() => {
    const saved = localStorage.getItem('neatlify_lang');
    return (saved as Language) || 'EN';
  });
  const [authModalOpen, setAuthModalOpen] = useState(false);
  const [authModalMode, setAuthModalMode] = useState<'login' | 'signup'>('login');

  const { user, loading: authLoading } = useAuth();
  const t = translations[lang];

  const openAuth = (mode: 'login' | 'signup') => {
    setAuthModalMode(mode);
    setAuthModalOpen(true);
  };

  useEffect(() => {
    localStorage.setItem('neatlify_lang', lang);
  }, [lang]);

  const toggleLang = () => setLang(prev => prev === 'EN' ? 'DE' : 'EN');

  // Construction-specific content
  const slides = {
    hero: {
      EN: {
        badge: 'FOR CONSTRUCTION & REAL ESTATE',
        title: 'Organize Your Job Site Photos in Seconds',
        subtitle: 'Stop wasting hours sorting through thousands of construction photos. Let AI categorize by trade, location, and project automatically.',
        cta: 'Download Free',
        secondary: 'See How It Works'
      },
      DE: {
        badge: 'FÜR BAU & IMMOBILIEN',
        title: 'Organisieren Sie Ihre Baustellenfotos in Sekunden',
        subtitle: 'Verschwenden Sie keine Stunden mehr mit dem Sortieren von tausenden Baufotos. Lassen Sie KI automatisch nach Gewerk, Standort und Projekt kategorisieren.',
        cta: 'Kostenlos herunterladen',
        secondary: 'So funktioniert es'
      }
    },
    problem: {
      EN: {
        title: 'The Problem Every Contractor Faces',
        subtitle: 'Sound familiar?',
        items: [
          { icon: <CameraIcon />, text: '10,000+ photos across multiple projects' },
          { icon: <FolderIcon />, text: 'Hours wasted searching for specific images' },
          { icon: <DocumentStackIcon />, text: 'Documentation chaos at project handover' },
          { icon: <TagIcon />, text: 'No consistent naming or organization' }
        ]
      },
      DE: {
        title: 'Das Problem, das jeder Bauunternehmer kennt',
        subtitle: 'Kommt Ihnen das bekannt vor?',
        items: [
          { icon: <CameraIcon />, text: '10.000+ Fotos über mehrere Projekte' },
          { icon: <FolderIcon />, text: 'Stunden verschwendet bei der Suche nach Bildern' },
          { icon: <DocumentStackIcon />, text: 'Dokumentationschaos bei Projektübergabe' },
          { icon: <TagIcon />, text: 'Keine einheitliche Benennung oder Organisation' }
        ]
      }
    },
    useCases: {
      EN: {
        title: 'Built for Construction Workflows',
        items: [
          {
            icon: <CameraIcon />,
            tag: 'PHOTO DOCUMENTATION',
            title: 'Job Site Photos',
            desc: 'AI recognizes electrical work, plumbing, framing, and more',
            backTitle: 'How it works',
            backDesc: 'Point Neatlify at your camera roll',
            backList: ['Auto-detect trade type', 'Sort by date & location', 'Create project folders']
          },
          {
            icon: <TagIcon />,
            tag: 'SMART LABELING',
            title: 'Progress Tracking',
            desc: 'Automatically label photos with descriptive names',
            backTitle: 'AI-Powered Labels',
            backDesc: 'No more IMG_4521.jpg',
            backList: ['Descriptive filenames', 'Trade-specific labels', 'Date stamps']
          },
          {
            icon: <BlueprintIcon />,
            tag: 'BLUEPRINTS & DOCS',
            title: 'Plan Management',
            desc: 'Organize PDFs, blueprints, and permits by project',
            backTitle: 'Document Control',
            backDesc: 'All plans in one place',
            backList: ['PDF categorization', 'Version control', 'Quick search']
          },
          {
            icon: <BuildingIcon />,
            tag: 'REAL ESTATE',
            title: 'Property Listings',
            desc: 'Sort property photos by room, feature, or address',
            backTitle: 'Listing Ready',
            backDesc: 'Perfect for agents',
            backList: ['Room detection', 'Feature tagging', 'MLS-ready folders']
          }
        ]
      },
      DE: {
        title: 'Entwickelt für Bau-Workflows',
        items: [
          {
            icon: <CameraIcon />,
            tag: 'FOTODOKUMENTATION',
            title: 'Baustellenfotos',
            desc: 'KI erkennt Elektro-, Sanitär-, Rohbauarbeiten und mehr',
            backTitle: 'So funktioniert es',
            backDesc: 'Richten Sie Neatlify auf Ihre Kamerarolle',
            backList: ['Auto-Erkennung Gewerk', 'Sortierung nach Datum & Ort', 'Projektordner erstellen']
          },
          {
            icon: <TagIcon />,
            tag: 'SMART LABELING',
            title: 'Fortschrittsverfolgung',
            desc: 'Fotos automatisch mit beschreibenden Namen versehen',
            backTitle: 'KI-gestützte Labels',
            backDesc: 'Schluss mit IMG_4521.jpg',
            backList: ['Beschreibende Dateinamen', 'Gewerk-spezifische Labels', 'Datumsstempel']
          },
          {
            icon: <BlueprintIcon />,
            tag: 'PLÄNE & DOKUMENTE',
            title: 'Planverwaltung',
            desc: 'PDFs, Baupläne und Genehmigungen nach Projekt organisieren',
            backTitle: 'Dokumentenkontrolle',
            backDesc: 'Alle Pläne an einem Ort',
            backList: ['PDF-Kategorisierung', 'Versionskontrolle', 'Schnellsuche']
          },
          {
            icon: <BuildingIcon />,
            tag: 'IMMOBILIEN',
            title: 'Immobilienanzeigen',
            desc: 'Immobilienfotos nach Raum, Merkmal oder Adresse sortieren',
            backTitle: 'Listing-fertig',
            backDesc: 'Perfekt für Makler',
            backList: ['Raumerkennung', 'Feature-Tagging', 'Portalfertige Ordner']
          }
        ]
      }
    },
    trades: {
      EN: {
        title: 'Works With All Trades',
        subtitle: 'AI trained to recognize construction-specific content',
        list: ['Electrician', 'Plumber', 'HVAC', 'Carpenter', 'Roofer', 'Mason', 'Painter', 'Drywall', 'Concrete', 'Landscaping', 'Demolition', 'Insulation']
      },
      DE: {
        title: 'Funktioniert mit allen Gewerken',
        subtitle: 'KI trainiert zur Erkennung von bauspezifischen Inhalten',
        list: ['Elektriker', 'Klempner', 'HLK', 'Zimmerer', 'Dachdecker', 'Maurer', 'Maler', 'Trockenbau', 'Beton', 'Landschaftsbau', 'Abbruch', 'Dämmung']
      }
    },
    testimonial: {
      EN: {
        quote: "We used to spend 2 hours every Friday organizing job site photos. Now it takes 5 minutes. Neatlify paid for itself in the first week.",
        author: "Mike Johnson",
        role: "General Contractor",
        company: "Johnson Construction LLC"
      },
      DE: {
        quote: "Wir haben jeden Freitag 2 Stunden mit dem Organisieren von Baustellenfotos verbracht. Jetzt dauert es 5 Minuten. Neatlify hat sich in der ersten Woche bezahlt gemacht.",
        author: "Michael Schmidt",
        role: "Bauunternehmer",
        company: "Schmidt Bau GmbH"
      }
    },
    cta: {
      EN: {
        title: 'Ready to Organize Your Job Sites?',
        subtitle: 'Join thousands of contractors who save hours every week',
        button: 'Download Neatlify Free',
        note: 'macOS 12+ • 50 free files included'
      },
      DE: {
        title: 'Bereit, Ihre Baustellen zu organisieren?',
        subtitle: 'Schließen Sie sich tausenden Bauunternehmern an, die jede Woche Stunden sparen',
        button: 'Neatlify kostenlos herunterladen',
        note: 'macOS 12+ • 50 kostenlose Dateien inklusive'
      }
    }
  };

  const content = {
    hero: slides.hero[lang],
    problem: slides.problem[lang],
    useCases: slides.useCases[lang],
    trades: slides.trades[lang],
    testimonial: slides.testimonial[lang],
    cta: slides.cta[lang]
  };

  return (
    <div className="min-h-screen relative overflow-x-hidden selection:bg-[#FFD93D] selection:text-[#2D3436]">
      {/* Background Decorations */}
      <div className="absolute top-40 -left-10 opacity-10 pointer-events-none">
        <ExcavatorIllustration className="w-48 h-auto" />
      </div>

      {/* Navbar */}
      <nav className="fixed top-0 left-0 right-0 bg-[#FAFAF8] bg-opacity-95 backdrop-blur-md z-50 border-b-4 border-[#2D3436] py-4">
        <div className="max-w-6xl mx-auto px-6 flex justify-between items-center">
          <a href="#/" className="flex items-center gap-3 cursor-pointer group">
            <div className="w-12 h-12 bg-[#29AB87] sketch-border flex items-center justify-center cartoon-shadow group-hover:scale-110 transition-all">
              <span className="text-white font-bold text-2xl">N</span>
            </div>
            <span className="text-3xl font-bold text-[#2D3436] tracking-tight">Neatlify</span>
          </a>

          <div className="hidden md:flex items-center gap-6 font-bold text-sm">
            <a href="#/" className="hover:text-[#29AB87] transition-all">{lang === 'EN' ? 'Home' : 'Startseite'}</a>
            <a href="#/#features" className="hover:text-[#29AB87] transition-all">{t.nav.features}</a>
            <a href="#/#pricing" className="hover:text-[#29AB87] transition-all">{t.nav.pricing}</a>
          </div>

          <div className="flex items-center gap-3">
            <a
              href="#/construction"
              className="hidden md:block sketch-border px-4 py-2 text-sm font-bold bg-[#FF6B6B] text-white cartoon-shadow-hover transition-all"
            >
              <HardHatIcon className="w-4 h-4 inline mr-2" />
              {lang === 'EN' ? 'Construction' : 'Bauwesen'}
            </a>
            <button
              onClick={toggleLang}
              className="sketch-border px-4 py-2 text-sm font-bold bg-[#FFD93D] cartoon-shadow-hover transition-all"
            >
              {lang === 'EN' ? 'EN | DE' : 'DE | EN'}
            </button>

            {user && !authLoading ? (
              <UserMenu onBuyCredits={() => window.location.href = '#/#pricing'} />
            ) : (
              <button
                onClick={() => openAuth('login')}
                className="sketch-border px-4 py-2 text-sm font-bold bg-white text-[#2D3436] cartoon-shadow-hover transition-all hover:bg-[#29AB87] hover:text-white"
              >
                {lang === 'EN' ? 'Sign In' : 'Anmelden'}
              </button>
            )}
          </div>
        </div>
      </nav>

      {/* SLIDE 1: Hero Section */}
      <section className="pt-44 pb-20 px-6 bg-[#2D3436] text-white relative overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <ConstructionSiteIllustration className="w-full h-full object-cover" />
        </div>
        <div className="max-w-6xl mx-auto grid md:grid-cols-2 gap-12 items-center relative z-10">
          <AnimatedSection className="space-y-6">
            <div className="inline-flex items-center gap-2 bg-[#FF6B6B] text-white px-4 py-2 rounded-full text-sm font-bold sketch-border cartoon-shadow">
              <HardHatIcon className="w-5 h-5" />
              {content.hero.badge}
            </div>
            <h1 className="text-4xl md:text-6xl font-black leading-tight">
              {content.hero.title}
            </h1>
            <p className="text-xl opacity-80 leading-relaxed max-w-lg">
              {content.hero.subtitle}
            </p>
            <div className="flex flex-col sm:flex-row gap-4 pt-4">
              <a href="/downloads/Neatlify.dmg" className="bg-[#29AB87] text-white px-8 py-4 rounded-full text-xl font-bold sketch-border cartoon-shadow-hover transition-all text-center pulse">
                {content.hero.cta}
              </a>
              <a href="#how-it-works" className="px-8 py-4 rounded-full text-xl font-bold sketch-border bg-white text-[#2D3436] cartoon-shadow-hover transition-all text-center">
                {content.hero.secondary}
              </a>
            </div>
          </AnimatedSection>
          <AnimatedSection delay={200} className="hidden md:block">
            <div className="sketch-border bg-white p-4 cartoon-shadow transform rotate-2 hover:rotate-0 transition-all">
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center">
                  <span className="font-black text-[#FF6B6B] block uppercase tracking-widest text-xs mb-2">Before</span>
                  <ConstructionSiteIllustration className="w-full h-auto" />
                </div>
                <div className="text-center">
                  <span className="font-black text-[#29AB87] block uppercase tracking-widest text-xs mb-2">After</span>
                  <OrganizedFilesIllustration className="w-full h-auto" />
                </div>
              </div>
            </div>
          </AnimatedSection>
        </div>
      </section>

      {/* SLIDE 2: Problem Section */}
      <section className="py-24 px-6 bg-[#FAFAF8] border-y-4 border-[#2D3436]">
        <div className="max-w-4xl mx-auto">
          <AnimatedSection className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-black mb-4">{content.problem.title}</h2>
            <p className="text-xl opacity-70">{content.problem.subtitle}</p>
          </AnimatedSection>
          <div className="grid sm:grid-cols-2 gap-6">
            {content.problem.items.map((item, i) => (
              <AnimatedSection key={i} delay={i * 100}>
                <div className="bg-white sketch-border p-6 cartoon-shadow flex items-start gap-4">
                  <div className="w-12 h-12 bg-[#FF6B6B] sketch-border flex items-center justify-center flex-shrink-0 text-white">
                    {item.icon}
                  </div>
                  <p className="font-bold text-lg">{item.text}</p>
                </div>
              </AnimatedSection>
            ))}
          </div>
        </div>
      </section>

      {/* SLIDE 3: Use Cases with Flip Cards */}
      <section id="how-it-works" className="py-24 px-6 bg-white">
        <div className="max-w-6xl mx-auto">
          <AnimatedSection className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-black mb-4">{content.useCases.title}</h2>
          </AnimatedSection>
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {content.useCases.items.map((useCase, i) => {
              const colors = ['#29AB87', '#FFD93D', '#FF6B6B', '#29AB87'];
              return (
                <AnimatedSection key={i} delay={i * 100}>
                  <FlipCard
                    className="h-[280px]"
                    front={
                      <div className="h-full flex flex-col card-content">
                        <div className="w-12 h-12 sketch-border flex items-center justify-center mb-3 flex-shrink-0" style={{backgroundColor: colors[i]}}>
                          <div className="text-white">{useCase.icon}</div>
                        </div>
                        <div className="text-[10px] font-black uppercase tracking-wider opacity-60 mb-1">{useCase.tag}</div>
                        <h3 className="text-lg font-bold mb-2">{useCase.title}</h3>
                        <p className="text-sm opacity-70 leading-relaxed">{useCase.desc}</p>
                      </div>
                    }
                    back={
                      <div className="h-full flex flex-col card-content">
                        <h3 className="text-base font-bold mb-2 text-[#FFD93D]">{useCase.backTitle}</h3>
                        <p className="text-xs opacity-80 mb-3 leading-relaxed">{useCase.backDesc}</p>
                        <ul className="text-xs space-y-1 mt-auto">
                          {useCase.backList.map((item: string, j: number) => (
                            <li key={j} className="flex items-center gap-2">
                              <span className="text-[#29AB87]">✓</span> {item}
                            </li>
                          ))}
                        </ul>
                      </div>
                    }
                  />
                </AnimatedSection>
              );
            })}
          </div>
        </div>
      </section>

      {/* SLIDE 4: Trades Section */}
      <section className="py-24 px-6 bg-[#2D3436] text-white">
        <div className="max-w-4xl mx-auto">
          <AnimatedSection className="text-center mb-12">
            <div className="flex items-center justify-center gap-3 mb-4">
              <TradesIcon className="w-10 h-10 text-[#FFD93D]" />
              <h2 className="text-4xl md:text-5xl font-black">{content.trades.title}</h2>
            </div>
            <p className="text-xl opacity-70">{content.trades.subtitle}</p>
          </AnimatedSection>
          <AnimatedSection>
            <div className="flex flex-wrap justify-center gap-3">
              {content.trades.list.map((trade, i) => (
                <span key={i} className="bg-white bg-opacity-10 px-5 py-3 rounded-full text-base font-bold sketch-border hover:bg-[#29AB87] transition-all cursor-default">
                  {trade}
                </span>
              ))}
            </div>
          </AnimatedSection>
        </div>
      </section>

      {/* SLIDE 5: Testimonial + CTA */}
      <section className="py-24 px-6 bg-[#FFD93D] border-y-4 border-[#2D3436]">
        <div className="max-w-4xl mx-auto">
          <AnimatedSection>
            <div className="bg-white sketch-border p-8 cartoon-shadow mb-16">
              <QuoteIcon className="w-12 h-12 text-[#29AB87] mb-4 opacity-50" />
              <p className="text-2xl mb-6 italic leading-relaxed">"{content.testimonial.quote}"</p>
              <div className="border-t-2 border-[#2D3436] border-opacity-10 pt-4">
                <div className="font-bold text-lg">{content.testimonial.author}</div>
                <div className="opacity-60">{content.testimonial.role}</div>
                <div className="opacity-40 text-sm">{content.testimonial.company}</div>
              </div>
            </div>
          </AnimatedSection>

          <AnimatedSection className="text-center">
            <h2 className="text-4xl md:text-5xl font-black mb-4 text-[#2D3436]">{content.cta.title}</h2>
            <p className="text-xl opacity-70 mb-8 text-[#2D3436]">{content.cta.subtitle}</p>
            <a href="/downloads/Neatlify.dmg" className="inline-block bg-[#29AB87] text-white px-10 py-5 rounded-full text-xl font-black sketch-border cartoon-shadow-hover transition-all pulse">
              {content.cta.button}
            </a>
            <p className="mt-4 text-sm opacity-60 text-[#2D3436]">{content.cta.note}</p>
          </AnimatedSection>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 px-6 bg-[#2D3436] text-white">
        <div className="max-w-6xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
          <a href="#/" className="flex items-center gap-3">
            <div className="w-10 h-10 bg-[#29AB87] sketch-border flex items-center justify-center">
              <span className="text-white font-bold text-xl">N</span>
            </div>
            <span className="text-xl font-bold">Neatlify</span>
          </a>
          <div className="flex gap-6 text-sm font-bold">
            <a href="#/" className="hover:text-[#29AB87] transition-all">{lang === 'EN' ? 'Home' : 'Startseite'}</a>
            <a href="#/#pricing" className="hover:text-[#29AB87] transition-all">{lang === 'EN' ? 'Pricing' : 'Preise'}</a>
            <a href="#/privacy" className="hover:text-[#29AB87] transition-all">{lang === 'EN' ? 'Privacy' : 'Datenschutz'}</a>
          </div>
          <div className="text-sm opacity-40">
            © 2025 Neatlify. All rights reserved.
          </div>
        </div>
      </footer>

      {/* Auth Modal */}
      <AuthModal
        isOpen={authModalOpen}
        onClose={() => setAuthModalOpen(false)}
        initialMode={authModalMode}
      />
    </div>
  );
};

export default ConstructionPage;
