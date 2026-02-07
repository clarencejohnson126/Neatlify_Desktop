
import React, { useState, useEffect, useRef } from 'react';
import { translations, Language } from './translations';
import { useAuth } from './contexts/AuthContext';
import AuthModal from './components/AuthModal';
import UserMenu from './components/UserMenu';
import {
  FolderIcon,
  AiScanIcon,
  ChecklistIcon,
  MessyDeskIllustration,
  CleanDeskIllustration,
  PencilIcon,
  PrivacyIcon,
  HistoryIcon,
  BicycleIllustration,
  PlantIllustration,
  StickyNoteIllustration,
  HardHatIcon,
  BlueprintIcon,
  BuildingIcon,
  CameraIcon,
  TagIcon,
  ConstructionSiteIllustration,
  OrganizedFilesIllustration,
  RealEstateIllustration,
  DocumentStackIcon,
  LaptopIllustration,
  ExcavatorIllustration,
  ConstructionWorkerIllustration,
  WomanWithLaptopIllustration,
  DocumentsIllustration,
  FilesImageIllustration,
  BookIcon,
  TradesIcon,
  QuoteIcon,
  MailIcon,
  GlobeIcon,
  ChatIcon
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

const LandingPage: React.FC = () => {
  const [lang, setLang] = useState<Language>(() => {
    const saved = localStorage.getItem('neatlify_lang');
    return (saved as Language) || 'EN';
  });
  const [openFaq, setOpenFaq] = useState<number | null>(null);
  const [authModalOpen, setAuthModalOpen] = useState(false);
  const [authModalMode, setAuthModalMode] = useState<'login' | 'signup'>('login');
  const [infographicOpen, setInfographicOpen] = useState(false);

  const { user, loading: authLoading } = useAuth();
  const t = translations[lang];

  const openAuth = (mode: 'login' | 'signup') => {
    setAuthModalMode(mode);
    setAuthModalOpen(true);
  };

  const [checkoutLoading, setCheckoutLoading] = useState<string | null>(null);

  const handleDownload = (e: React.MouseEvent<HTMLAnchorElement | HTMLButtonElement>) => {
    // Require login first - NO EXCEPTIONS
    if (!user) {
      e.preventDefault();
      openAuth('signup');
      return;
    }
    // User is logged in, start download
    e.preventDefault();
    const downloadUrl = 'https://github.com/clarencejohnson126/Neatlify_Desktop/releases/download/v1.3.3/Neatlify-Desktop-1.3.3.dmg';
    window.location.href = downloadUrl;
  };

  const handleCheckout = async (productType: 'starter' | 'pro' | 'business') => {
    // Require login first
    if (!user) {
      openAuth('login');
      return;
    }

    setCheckoutLoading(productType);
    try {
      const response = await fetch('https://nlvlwrhayrvberdyjgjx.supabase.co/functions/v1/create-checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          productType,
          userEmail: user.email,
          successUrl: `${window.location.origin}/#/success?session_id={CHECKOUT_SESSION_ID}`,
          cancelUrl: `${window.location.origin}/#pricing`,
        }),
      });

      const data = await response.json();
      if (data.url) {
        window.location.href = data.url;
      } else {
        console.error('No checkout URL returned:', data);
        alert('Failed to create checkout. Please try again.');
      }
    } catch (error) {
      console.error('Checkout error:', error);
      alert('Failed to create checkout. Please try again.');
    } finally {
      setCheckoutLoading(null);
    }
  };

  useEffect(() => {
    localStorage.setItem('neatlify_lang', lang);
  }, [lang]);

  const toggleLang = () => setLang(prev => prev === 'EN' ? 'DE' : 'EN');

  const featureIcons = [
    { icon: <PencilIcon />, color: '#FFD93D' },
    { icon: <ChecklistIcon />, color: '#FF6B6B' },
    { icon: <FolderIcon />, color: '#29AB87' },
    { icon: <PrivacyIcon />, color: '#2D3436' },
    { icon: <HistoryIcon />, color: '#FF6B6B' },
    { icon: <TagIcon />, color: '#29AB87' },
    { icon: <MailIcon />, color: '#FF6B6B' },
    { icon: <GlobeIcon />, color: '#29AB87' },
    { icon: <ChatIcon />, color: '#FFD93D' },
  ];

  const featureKeys = ['images', 'docs', 'categories', 'privacy', 'undo', 'labeling', 'emails', 'multilingual', 'natural'] as const;

  return (
    <div className="min-h-screen relative overflow-x-hidden selection:bg-[#FFD93D] selection:text-[#2D3436]">

      {/* Navbar */}
      <nav className="fixed top-0 left-0 right-0 bg-[#FAFAF8] bg-opacity-95 backdrop-blur-md z-50 border-b-4 border-[#2D3436] py-4">
        <div className="max-w-6xl mx-auto px-6 flex justify-between items-center">
          <div className="flex items-center gap-3 cursor-pointer group" onClick={() => window.scrollTo({top: 0, behavior: 'smooth'})}>
            <div className="w-12 h-12 bg-[#29AB87] sketch-border flex items-center justify-center cartoon-shadow group-hover:scale-110 transition-all">
              <span className="text-white font-bold text-2xl">N</span>
            </div>
            <span className="text-3xl font-bold text-[#2D3436] tracking-tight">Neatlify</span>
          </div>

          <div className="hidden md:flex items-center gap-6 font-bold text-sm">
            <a href="#features" className="hover:text-[#29AB87] transition-all">{t.nav.features}</a>
            <a href="#how" className="hover:text-[#29AB87] transition-all">{t.nav.howItWorks}</a>
            <a href="#pricing" className="hover:text-[#29AB87] transition-all">{t.nav.pricing}</a>
          </div>

          <div className="flex items-center gap-3">
            {/* Real Estate & Construction link */}
            <a
              href="#/construction"
              className="hidden md:flex items-center gap-2 sketch-border px-4 py-2 text-sm font-bold bg-[#FF6B6B] text-white cartoon-shadow-hover transition-all"
            >
              <HardHatIcon className="w-4 h-4" />
              {lang === 'EN' ? 'Real Estate & Construction' : 'Immobilien & Bau'}
            </a>

            <button
              onClick={toggleLang}
              className="sketch-border px-4 py-2 text-sm font-bold bg-[#FFD93D] cartoon-shadow-hover transition-all"
            >
              {lang === 'EN' ? 'EN | DE' : 'DE | EN'}
            </button>

            {/* Auth section - always show Sign In unless explicitly logged in */}
            {user && !authLoading ? (
              <UserMenu onBuyCredits={() => document.getElementById('pricing')?.scrollIntoView({ behavior: 'smooth' })} />
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

      {/* Hero Section */}
      <section className="pt-44 pb-20 px-6 relative">
        <div className="max-w-6xl mx-auto">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <AnimatedSection className="space-y-6 relative z-10">
              <div className="flex flex-wrap gap-3">
                <div className="inline-block bg-[#29AB87] text-white px-4 py-1 rounded-full text-sm font-bold sketch-border cartoon-shadow">
                  {t.hero.badges.personal} ✨
                </div>
                <div className="inline-block bg-[#FF6B6B] text-white px-4 py-1 rounded-full text-sm font-bold sketch-border cartoon-shadow wiggle">
                  {t.hero.badges.business} 🏗️
                </div>
              </div>
              <h1 className="text-5xl md:text-6xl font-bold leading-[0.95] text-[#2D3436]">
                {t.hero.headline}
              </h1>
              <p className="text-xl text-[#2D3436] opacity-80 leading-relaxed font-medium">
                {t.hero.subheadline}
              </p>
              <p className="text-base text-[#2D3436] opacity-60 font-medium border-l-4 border-[#FFD93D] pl-4">
                {t.hero.useCases}
              </p>
              <div className="flex flex-col sm:flex-row gap-4 pt-2">
                <button
                  onClick={handleDownload}
                  className="bg-[#29AB87] text-white px-8 py-4 rounded-full text-xl font-bold sketch-border cartoon-shadow-hover transition-all text-center pulse cursor-pointer"
                >
                  {t.hero.cta}
                </button>
                <a href="#how" className="px-8 py-4 rounded-full text-xl font-bold sketch-border bg-white text-[#2D3436] cartoon-shadow-hover transition-all text-center">
                  {t.hero.secondary}
                </a>
              </div>
              <div className="text-sm text-[#2D3436] opacity-60 flex items-center gap-3 font-bold">
                <span className="bg-[#FFD93D] p-2 rounded-lg sketch-border"></span>
                {t.hero.requirements} • {t.hero.version}
              </div>
            </AnimatedSection>

            {/* Hero Image */}
            <AnimatedSection delay={200} className="hidden lg:block">
              <div className="sketch-border cartoon-shadow bg-white p-2 transform rotate-1 hover:rotate-0 transition-all">
                <img
                  src="/hero-before-after.png"
                  alt="Before and After - Messy files transformed into organized folders with Neatlify"
                  className="w-full h-auto"
                />
              </div>
            </AnimatedSection>
          </div>
        </div>
      </section>

      {/* How It Works Section - Dark background */}
      <section id="how" className="py-24 bg-[#2D3436] text-white border-y-4 border-[#2D3436] relative overflow-hidden">
        <div className="max-w-6xl mx-auto px-6 relative z-10">
          <AnimatedSection className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold">{t.how.title}</h2>
          </AnimatedSection>
          <div className="grid md:grid-cols-4 gap-8 relative">
            {[
              { icon: <FolderIcon />, ...t.how.step1, color: '#29AB87', bgCard: '#29AB87' },
              { icon: <AiScanIcon />, ...t.how.step2, color: '#FF6B6B', bgCard: '#FF6B6B', hasExample: true },
              { icon: <PencilIcon />, ...t.how.step3, color: '#FFD93D', bgCard: '#FFD93D' },
              { icon: <ChecklistIcon />, ...t.how.step4, color: '#29AB87', bgCard: '#29AB87' }
            ].map((step, i) => (
              <AnimatedSection key={i} delay={i * 150} className="flex flex-col items-center text-center group">
                <div className="sketch-border p-6 cartoon-shadow transition-all group-hover:scale-105 group-hover:-rotate-1 h-full" style={{backgroundColor: step.bgCard}}>
                  <div className="w-16 h-16 bg-white sketch-border mb-4 flex items-center justify-center mx-auto" style={{color: step.color}}>
                    <div className="scale-110">{step.icon}</div>
                  </div>
                  <div className="text-xs font-black opacity-60 mb-2">STEP {i + 1}</div>
                  <h3 className="text-xl font-bold mb-2 text-white">{step.title}</h3>
                  <p className="text-sm opacity-90 leading-relaxed">{step.desc}</p>
                  {step.hasExample && step.example && (
                    <div className="mt-3 bg-white text-[#2D3436] px-4 py-2 rounded-lg text-xs font-mono italic sketch-border">
                      {step.example}
                    </div>
                  )}
                </div>
              </AnimatedSection>
            ))}
          </div>

          {/* Infographic */}
          <AnimatedSection delay={300} className="mt-16">
            <div
              className="bg-white sketch-border cartoon-shadow p-4 max-w-4xl mx-auto cursor-pointer hover:scale-[1.02] transition-all relative group"
              onClick={() => setInfographicOpen(true)}
            >
              <img
                src="/infographic-how-it-works.png"
                alt="Neatlify workflow: Select folder, describe organization, content analyzed, files organized"
                className="w-full h-auto"
              />
              <div className="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-10 transition-all flex items-center justify-center">
                <span className="opacity-0 group-hover:opacity-100 bg-white text-[#2D3436] px-4 py-2 rounded-full font-bold text-sm sketch-border transition-all">
                  {lang === 'EN' ? 'Click to enlarge' : 'Klicken zum Vergrößern'}
                </span>
              </div>
            </div>
          </AnimatedSection>
        </div>
      </section>

      {/* Features Grid with Flip Cards - White background */}
      <section id="features" className="py-24 px-6 bg-white">
        <div className="max-w-6xl mx-auto">
          <AnimatedSection className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold">{lang === 'EN' ? 'Features' : 'Funktionen'}</h2>
          </AnimatedSection>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {featureKeys.map((key, i) => {
              const feat = t.features[key];
              const { icon, color } = featureIcons[i];
              return (
                <AnimatedSection key={i} delay={i * 100}>
                  <FlipCard
                    front={
                      <div className="h-full flex flex-col card-content">
                        <div className="mb-4 w-12 h-12 sketch-border flex items-center justify-center flex-shrink-0" style={{backgroundColor: color, color: 'white'}}>
                          {icon}
                        </div>
                        <h3 className="text-xl font-bold mb-2">{feat.title}</h3>
                        <p className="text-[#2D3436] opacity-70 text-sm leading-relaxed">{feat.desc}</p>
                      </div>
                    }
                    back={
                      <div className="h-full flex flex-col card-content">
                        <h3 className="text-lg font-bold mb-2 text-[#FFD93D]">{feat.backTitle}</h3>
                        <p className="text-sm opacity-80 mb-3 leading-relaxed">{feat.backDesc}</p>
                        <ul className="text-xs space-y-1 mt-auto">
                          {feat.backList.map((item: string, j: number) => (
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

      {/* Use Cases Section - Coral/Red background */}
      <section className="py-24 px-6 bg-[#FF6B6B] text-white border-y-4 border-[#2D3436]">
        <div className="max-w-6xl mx-auto">
          <AnimatedSection className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">{t.useCasesSection.title}</h2>
            <p className="text-xl opacity-90">{t.useCasesSection.subtitle}</p>
          </AnimatedSection>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {t.useCasesSection.cases.map((useCase, i) => {
              const icons: Record<string, React.ReactNode> = {
                camera: <CameraIcon />,
                building: <BuildingIcon />,
                hardhat: <HardHatIcon />,
                house: <RealEstateIllustration className="w-10 h-10" />,
                book: <BookIcon />,
                folder: <FolderIcon />
              };
              const cardColors = ['#FFD93D', '#29AB87', '#2D3436', '#FFD93D', '#29AB87', '#2D3436'];
              const iconColors = ['#2D3436', '#FFFFFF', '#FFFFFF', '#2D3436', '#FFFFFF', '#FFFFFF'];
              return (
                <AnimatedSection key={i} delay={i * 100}>
                  <div className="bg-white text-[#2D3436] sketch-border p-6 cartoon-shadow hover:-translate-y-1 transition-all h-full">
                    <div className="w-12 h-12 sketch-border flex items-center justify-center mb-4" style={{backgroundColor: cardColors[i], color: iconColors[i]}}>
                      {icons[useCase.icon]}
                    </div>
                    <h3 className="text-xl font-bold mb-2">{useCase.title}</h3>
                    <p className="text-sm opacity-70">{useCase.desc}</p>
                  </div>
                </AnimatedSection>
              );
            })}
          </div>
        </div>
      </section>


      {/* How AI Works Section - White background */}
      <section className="py-24 px-6 bg-white border-y-4 border-[#2D3436]">
        <div className="max-w-4xl mx-auto">
          <AnimatedSection className="text-center mb-16">
            <div className="inline-block bg-[#29AB87] text-white px-4 py-1 rounded-full text-sm font-bold mb-4">
              {t.howAiWorks.badge}
            </div>
            <h2 className="text-4xl md:text-5xl font-bold mb-4">{t.howAiWorks.title}</h2>
            <p className="text-xl opacity-70">{t.howAiWorks.subtitle}</p>
          </AnimatedSection>

          <div className="space-y-6 mb-12">
            {t.howAiWorks.steps.map((step, i) => {
              const stepColors = ['#29AB87', '#FFD93D', '#FF6B6B'];
              const textColors = ['#FFFFFF', '#2D3436', '#FFFFFF'];
              return (
                <AnimatedSection key={i} delay={i * 150}>
                  <div className="flex gap-6 items-start sketch-border p-6 cartoon-shadow hover:-translate-y-1 transition-all" style={{backgroundColor: stepColors[i]}}>
                    <div className="w-12 h-12 rounded-full bg-white flex items-center justify-center font-black text-xl flex-shrink-0 sketch-border" style={{color: stepColors[i]}}>
                      {i + 1}
                    </div>
                    <div style={{color: textColors[i]}}>
                      <h3 className="text-xl font-bold mb-2">{step.title}</h3>
                      <p className="opacity-90">{step.desc}</p>
                    </div>
                  </div>
                </AnimatedSection>
              );
            })}
          </div>

          <AnimatedSection className="text-center">
            <div className="inline-flex items-center gap-2 bg-[#2D3436] text-white px-6 py-3 rounded-full font-bold sketch-border">
              <PrivacyIcon className="w-5 h-5" />
              {t.howAiWorks.privacy}
            </div>
          </AnimatedSection>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-24 px-6 bg-[#FFD93D] border-y-4 border-[#2D3436]">
        <div className="max-w-6xl mx-auto">
          <AnimatedSection className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold mb-4">{t.testimonials.title}</h2>
            <p className="text-xl opacity-70">{t.testimonials.subtitle}</p>
          </AnimatedSection>

          <div className="grid md:grid-cols-3 gap-6">
            {t.testimonials.items.map((item, i) => (
              <AnimatedSection key={i} delay={i * 150}>
                <div className="bg-white sketch-border p-6 cartoon-shadow h-full flex flex-col">
                  <QuoteIcon className="w-8 h-8 text-[#29AB87] mb-4 opacity-50" />
                  <p className="text-lg mb-6 flex-grow italic">"{item.quote}"</p>
                  <div className="border-t-2 border-[#2D3436] border-opacity-10 pt-4">
                    <div className="font-bold">{item.author}</div>
                    <div className="text-sm opacity-60">{item.role}</div>
                    <div className="text-sm opacity-40">{item.company}</div>
                  </div>
                </div>
              </AnimatedSection>
            ))}
          </div>
        </div>
      </section>

      {/* FAQ Section - Light background */}
      <section className="py-24 px-6 bg-[#FAFAF8]">
        <div className="max-w-3xl mx-auto">
          <AnimatedSection className="text-center mb-16">
            <h2 className="text-4xl md:text-5xl font-bold">{t.faq.title}</h2>
          </AnimatedSection>

          <div className="space-y-4">
            {t.faq.items.map((item, i) => (
              <AnimatedSection key={i} delay={i * 50}>
                <div
                  className="sketch-border bg-white cartoon-shadow overflow-hidden cursor-pointer hover:-translate-y-1 transition-all"
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                >
                  <div className="p-6 flex justify-between items-center">
                    <h3 className="font-bold text-lg pr-4">{item.q}</h3>
                    <span className={`text-2xl transition-transform ${openFaq === i ? 'rotate-45' : ''}`}>+</span>
                  </div>
                  <div className={`px-6 overflow-hidden transition-all duration-300 ${openFaq === i ? 'pb-6 max-h-40' : 'max-h-0'}`}>
                    <p className="opacity-70">{item.a}</p>
                  </div>
                </div>
              </AnimatedSection>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-24 px-6 bg-[#29AB87] text-white border-y-4 border-[#2D3436]">
        <div className="max-w-6xl mx-auto">
          <AnimatedSection className="text-center mb-16">
            <h2 className="text-5xl md:text-6xl font-black mb-6 drop-shadow-lg">{t.pricing.title}</h2>
          </AnimatedSection>

          <div className="grid md:grid-cols-4 gap-6">
            {/* Starter */}
            <AnimatedSection>
              <div className="bg-white text-[#2D3436] sketch-border p-6 flex flex-col items-center cartoon-shadow h-full">
                <h3 className="text-xl font-black mb-3 uppercase">{t.pricing.starter.name}</h3>
                <div className="text-4xl font-black mb-2 text-[#FF6B6B]">{t.pricing.starter.price}</div>
                <div className="font-bold mb-2">{t.pricing.starter.files}</div>
                <div className="text-xs opacity-60 mb-4 font-bold">{t.pricing.starter.rate}</div>
                <div className="bg-[#FFD93D] p-2 text-xs font-black mb-6 sketch-border w-full text-center">
                  {t.pricing.starter.tag}
                </div>
                <button
                  onClick={() => handleCheckout('starter')}
                  disabled={checkoutLoading === 'starter'}
                  className="mt-auto w-full py-3 bg-[#2D3436] text-white rounded-full font-black sketch-border cartoon-shadow-hover text-center transition-all text-sm disabled:opacity-50"
                >
                  {checkoutLoading === 'starter' ? 'Loading...' : t.pricing.buy}
                </button>
              </div>
            </AnimatedSection>

            {/* Pro */}
            <AnimatedSection delay={100}>
              <div className="bg-[#FFD93D] text-[#2D3436] sketch-border p-6 flex flex-col items-center cartoon-shadow relative transform md:scale-105 z-20 h-full">
                <div className="absolute -top-4 bg-[#FF6B6B] text-white px-4 py-1 rounded-full text-xs font-black sketch-border cartoon-shadow wiggle">
                  {t.pricing.pro.badge}
                </div>
                <h3 className="text-xl font-black mb-3 uppercase mt-2">{t.pricing.pro.name}</h3>
                <div className="text-5xl font-black mb-2 text-[#29AB87]">{t.pricing.pro.price}</div>
                <div className="font-bold mb-2">{t.pricing.pro.files}</div>
                <div className="text-xs opacity-60 mb-4 font-bold">{t.pricing.pro.rate}</div>
                <div className="bg-white p-2 text-xs font-black mb-6 sketch-border w-full text-center">
                  {t.pricing.pro.tag}
                </div>
                <button
                  onClick={() => handleCheckout('pro')}
                  disabled={checkoutLoading === 'pro'}
                  className="mt-auto w-full py-3 bg-[#29AB87] text-white rounded-full font-black sketch-border cartoon-shadow-hover text-center transition-all text-sm disabled:opacity-50"
                >
                  {checkoutLoading === 'pro' ? 'Loading...' : t.pricing.buy}
                </button>
              </div>
            </AnimatedSection>

            {/* Business */}
            <AnimatedSection delay={200}>
              <div className="bg-white text-[#2D3436] sketch-border p-6 flex flex-col items-center cartoon-shadow relative h-full">
                <div className="absolute -top-4 bg-[#FF6B6B] text-white px-4 py-1 rounded-full text-xs font-black sketch-border cartoon-shadow">
                  {t.pricing.business.badge}
                </div>
                <h3 className="text-xl font-black mb-3 uppercase mt-2">{t.pricing.business.name}</h3>
                <div className="text-4xl font-black mb-2 text-[#FF6B6B]">{t.pricing.business.price}</div>
                <div className="font-bold mb-2">{t.pricing.business.files}</div>
                <div className="text-xs opacity-60 mb-4 font-bold">{t.pricing.business.rate}</div>
                <div className="bg-[#FFD93D] p-2 text-xs font-black mb-6 sketch-border w-full text-center">
                  {t.pricing.business.tag}
                </div>
                <button
                  onClick={() => handleCheckout('business')}
                  disabled={checkoutLoading === 'business'}
                  className="mt-auto w-full py-3 bg-[#2D3436] text-white rounded-full font-black sketch-border cartoon-shadow-hover text-center transition-all text-sm disabled:opacity-50"
                >
                  {checkoutLoading === 'business' ? 'Loading...' : t.pricing.buy}
                </button>
              </div>
            </AnimatedSection>

            {/* Enterprise */}
            <AnimatedSection delay={300}>
              <div className="bg-[#FAFAF8] bg-opacity-10 text-white sketch-border p-6 flex flex-col items-center cartoon-shadow h-full">
                <h3 className="text-xl font-black mb-3 uppercase">{t.pricing.enterprise.name}</h3>
                <div className="text-2xl font-black mb-2">{t.pricing.enterprise.price}</div>
                <div className="font-bold mb-2">{t.pricing.enterprise.files}</div>
                <div className="text-xs opacity-80 mb-4 font-bold">{t.pricing.enterprise.rate}</div>
                <div className="bg-[#2D3436] p-2 text-xs font-black mb-6 sketch-border w-full text-center">
                  {t.pricing.enterprise.tag}
                </div>
                <a href="mailto:hello@neatlify.app" className="mt-auto w-full py-3 bg-white text-[#2D3436] rounded-full font-black sketch-border cartoon-shadow-hover text-center transition-all text-sm">
                  {t.pricing.contact}
                </a>
              </div>
            </AnimatedSection>
          </div>
        </div>
      </section>

      {/* Final CTA Section */}
      <section className="py-24 px-6 bg-[#2D3436] text-white relative overflow-hidden">
        <div className="max-w-3xl mx-auto text-center relative z-10">
          <AnimatedSection>
            <h2 className="text-4xl md:text-6xl font-black mb-6">{t.finalCta.title}</h2>
            <p className="text-xl opacity-80 mb-10">{t.finalCta.subtitle}</p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center mb-8">
              <button
                onClick={handleDownload}
                className="bg-[#29AB87] text-white px-10 py-5 rounded-full text-xl font-black sketch-border cartoon-shadow-hover transition-all pulse cursor-pointer"
              >
                {t.finalCta.cta}
              </button>
              <a href="#pricing" className="bg-white text-[#2D3436] px-10 py-5 rounded-full text-xl font-black sketch-border cartoon-shadow-hover transition-all">
                {t.finalCta.secondary}
              </a>
            </div>
            <p className="text-sm opacity-50">{t.finalCta.trust}</p>
          </AnimatedSection>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-16 px-6 bg-[#2D3436] text-white border-t-4 border-[#29AB87]">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col md:flex-row justify-between items-center gap-8 mb-12">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 bg-[#29AB87] sketch-border flex items-center justify-center">
                <span className="text-white font-bold text-2xl">N</span>
              </div>
              <span className="text-2xl font-bold tracking-tighter">Neatlify</span>
            </div>
            <div className="flex flex-wrap justify-center gap-8 text-sm font-bold">
              <a href="#/privacy" className="hover:text-[#FF6B6B] transition-all">{t.footer.privacy}</a>
              <a href="#/impressum" className="hover:text-[#FF6B6B] transition-all">{lang === 'EN' ? 'Impressum' : 'Impressum'}</a>
              <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/" target="_blank" rel="noopener noreferrer" className="hover:text-[#FF6B6B] transition-all">{lang === 'EN' ? 'Terms of Service' : 'Nutzungsbedingungen'}</a>
              <a href="mailto:hello@neatlify.app" className="hover:text-[#FF6B6B] transition-all">{t.footer.support}</a>
            </div>
            <div className="flex items-center gap-3">
              <a href="https://www.rebelzai.com" target="_blank" rel="noopener noreferrer" className="w-10 h-10 flex items-center justify-center overflow-hidden cursor-pointer hover:opacity-70 transition-all" title="Rebelz AI">
                <img src="/rebelzai-logo.png" alt="Rebelz AI" className="w-8 h-8 object-contain" />
              </a>
              <a href="https://www.angebots-agent.de" target="_blank" rel="noopener noreferrer" className="w-[60px] h-[60px] flex items-center justify-center overflow-hidden cursor-pointer hover:opacity-70 transition-all" title="Angebots-Agent">
                <img src="/angebots-agent-logo.png" alt="Angebots-Agent" className="w-12 h-12 object-contain" />
              </a>
              <a href="https://www.snapplan.tech" target="_blank" rel="noopener noreferrer" className="w-10 h-10 flex items-center justify-center overflow-hidden cursor-pointer hover:opacity-70 transition-all" title="SnapPlan">
                <img src="/snapplan-logo.png" alt="SnapPlan" className="w-8 h-8 object-contain" />
              </a>
              <a href="https://www.ki-bauunternehmer.de" target="_blank" rel="noopener noreferrer" className="w-10 h-10 flex items-center justify-center overflow-hidden cursor-pointer hover:opacity-70 transition-all" title="KI-Bauunternehmer">
                <img src="/ki-bauunternehmer-logo.png" alt="KI-Bauunternehmer" className="w-8 h-8 object-contain" />
              </a>
            </div>
          </div>
          <div className="pt-8 border-t border-white border-opacity-10 text-center text-sm opacity-40">
            {t.footer.rights}
          </div>
        </div>
      </footer>

      {/* Auth Modal */}
      <AuthModal
        isOpen={authModalOpen}
        onClose={() => setAuthModalOpen(false)}
        initialMode={authModalMode}
      />

      {/* Infographic Lightbox */}
      {infographicOpen && (
        <div
          className="fixed inset-0 z-[100] flex items-center justify-center p-4 md:p-8"
          onClick={() => setInfographicOpen(false)}
        >
          <div className="absolute inset-0 bg-[#2D3436] bg-opacity-90 backdrop-blur-sm" />
          <div className="relative max-w-7xl w-full max-h-[90vh] overflow-auto">
            <button
              onClick={() => setInfographicOpen(false)}
              className="absolute -top-12 right-0 text-white text-xl font-bold hover:text-[#FF6B6B] transition-colors flex items-center gap-2"
            >
              {lang === 'EN' ? 'Close' : 'Schließen'} ✕
            </button>
            <img
              src="/infographic-how-it-works.png"
              alt="Neatlify workflow infographic"
              className="w-full h-auto rounded-lg shadow-2xl"
              onClick={(e) => e.stopPropagation()}
            />
          </div>
        </div>
      )}
    </div>
  );
};

export default LandingPage;
