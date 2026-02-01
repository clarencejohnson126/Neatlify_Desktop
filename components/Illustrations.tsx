
import React from 'react';

export const FolderIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M4 20h16a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.93a2 2 0 0 1-1.66-.9l-.82-1.2A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13c0 1.1.9 2 2 2Z"/>
  </svg>
);

export const AiScanIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M3 7V5a2 2 0 0 1 2-2h2"/>
    <path d="M17 3h2a2 2 0 0 1 2 2v2"/>
    <path d="M21 17v2a2 2 0 0 1-2 2h-2"/>
    <path d="M7 21H5a2 2 0 0 1-2-2v-2"/>
    <circle cx="12" cy="12" r="3"/>
    <path d="M7 12h10"/>
    <path d="M12 7v10"/>
  </svg>
);

export const ChecklistIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="m9 11 3 3L22 4"/>
    <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
  </svg>
);

export const PencilIcon = ({ className }: { className?: string }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/>
    <path d="m15 5 4 4"/>
  </svg>
);

export const PrivacyIcon = ({ className }: { className?: string }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10"/>
  </svg>
);

export const HistoryIcon = ({ className }: { className?: string }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
    <path d="M3 3v5h5"/>
    <path d="M12 7v5l4 2"/>
  </svg>
);

export const CloudOffIcon = ({ className }: { className?: string }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="m2 2 20 20"/>
    <path d="M5.782 5.782A7 7 0 0 0 9 19h8.5a4.5 4.5 0 0 0 1.307-.193"/>
    <path d="M22.5 15a4.5 4.5 0 0 0-4.773-4.473"/>
    <path d="M17.5 8.5a7 7 0 0 0-11.236 1.236"/>
  </svg>
);

export const MessyDeskIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 200 150" className={className}>
    <rect x="20" y="100" width="160" height="10" rx="2" fill="#2D3436" stroke="#2D3436" strokeWidth="1"/>
    <rect x="40" y="110" width="8" height="35" fill="#2D3436" stroke="#2D3436" strokeWidth="1" />
    <rect x="152" y="110" width="8" height="35" fill="#2D3436" stroke="#2D3436" strokeWidth="1" />
    {/* Scattered papers */}
    <rect x="30" y="85" width="28" height="18" fill="white" stroke="#2D3436" strokeWidth="1.5" transform="rotate(-15 42 92)" />
    <rect x="65" y="78" width="28" height="18" fill="white" stroke="#2D3436" strokeWidth="1.5" transform="rotate(25 72 87)" />
    <rect x="105" y="88" width="28" height="18" fill="white" stroke="#2D3436" strokeWidth="1.5" transform="rotate(-10 112 95)" />
    <rect x="135" y="72" width="28" height="18" fill="white" stroke="#2D3436" strokeWidth="1.5" transform="rotate(50 142 82)" />
    {/* Messy pile */}
    <rect x="85" y="88" width="28" height="18" fill="white" stroke="#2D3436" strokeWidth="1.5" transform="rotate(-5 95 95)" />
    <rect x="82" y="86" width="28" height="18" fill="#FFD93D" stroke="#2D3436" strokeWidth="1.5" transform="rotate(2 95 95)" />
    {/* Coffee cup */}
    <path d="M165 85 h12 v12 a6 6 0 0 1 -6 6 h-6 z" fill="#FF6B6B" stroke="#2D3436" strokeWidth="2" />
    <path d="M177 88 h4 a3 3 0 0 1 0 6 h-4" fill="none" stroke="#2D3436" strokeWidth="2" />
    {/* Steam */}
    <path d="M168 75 q2 -5 0 -10 M173 75 q2 -5 0 -10" fill="none" stroke="#2D3436" strokeWidth="1.5" />
  </svg>
);

export const CleanDeskIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 200 150" className={className}>
    <rect x="20" y="100" width="160" height="10" rx="2" fill="#2D3436" stroke="#2D3436" strokeWidth="1"/>
    <rect x="40" y="110" width="8" height="35" fill="#2D3436" stroke="#2D3436" strokeWidth="1" />
    <rect x="152" y="110" width="8" height="35" fill="#2D3436" stroke="#2D3436" strokeWidth="1" />
    {/* Neat stack */}
    <rect x="85" y="82" width="35" height="18" fill="white" stroke="#2D3436" strokeWidth="2" />
    <rect x="85" y="78" width="35" height="18" fill="white" stroke="#2D3436" strokeWidth="2" />
    <rect x="85" y="74" width="35" height="18" fill="#FFD93D" stroke="#2D3436" strokeWidth="2" />
    {/* Laptop */}
    <rect x="35" y="65" width="45" height="30" rx="2" fill="#29AB87" stroke="#2D3436" strokeWidth="2" />
    <rect x="30" y="95" width="55" height="5" rx="1" fill="#2D3436" />
    <circle cx="57" cy="80" r="3" fill="white" opacity="0.5" />
    {/* Plant */}
    <rect x="145" y="88" width="12" height="12" fill="#FF6B6B" stroke="#2D3436" strokeWidth="2" />
    <path d="M151 88 v-15 q-8 0 -8 -8 q8 8 8 8 q8 -8 8 -8 q-8 8 -8 8" fill="#29AB87" stroke="#2D3436" strokeWidth="1.5" />
  </svg>
);

export const BicycleIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 100 60" className={className} fill="none" stroke="#2D3436" strokeWidth="2.5">
    <circle cx="20" cy="40" r="15" />
    <circle cx="80" cy="40" r="15" />
    <path d="M20 40 L50 40 L70 20 L40 20 Z" />
    <path d="M50 40 L50 20 M70 20 L80 40" />
    <path d="M40 20 L35 15 M45 20 L45 12 h10" />
  </svg>
);

export const PlantIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 60 100" className={className} fill="none" stroke="#2D3436" strokeWidth="3">
    <path d="M30 100 V40" />
    <path d="M30 80 Q10 70 5 50" fill="#29AB87" strokeLinecap="round" />
    <path d="M30 65 Q50 55 55 35" fill="#29AB87" strokeLinecap="round" />
    <path d="M30 45 Q20 30 30 10 Q40 30 30 45" fill="#FF6B6B" />
  </svg>
);

export const StickyNoteIllustration = ({text, color, className}: {text: string, color: string, className?: string}) => (
  <svg viewBox="0 0 100 100" className={className}>
    <path d="M5 5 h90 v70 l-20 20 h-70 z" fill={color} stroke="#2D3436" strokeWidth="3" />
    <path d="M75 75 l20 20" stroke="#2D3436" strokeWidth="3" />
    <text x="20" y="45" font-family="Quicksand" font-weight="bold" font-size="12" fill="#2D3436">{text}</text>
  </svg>
);

// Construction & Real Estate Illustrations

export const HardHatIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M2 18a1 1 0 0 0 1 1h18a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1v2z"/>
    <path d="M10 15V6.5a3.5 3.5 0 0 1 7 0V15"/>
    <path d="M14 6.5a3.5 3.5 0 0 0-7 0V15"/>
  </svg>
);

export const BlueprintIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M3 7V5a2 2 0 0 1 2-2h2"/>
    <path d="M17 3h2a2 2 0 0 1 2 2v2"/>
    <path d="M21 17v2a2 2 0 0 1-2 2h-2"/>
    <path d="M7 21H5a2 2 0 0 1-2-2v-2"/>
    <rect x="7" y="7" width="10" height="10" rx="1"/>
    <path d="M7 12h10"/>
    <path d="M12 7v10"/>
  </svg>
);

export const BuildingIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <rect x="4" y="2" width="16" height="20" rx="2"/>
    <path d="M9 22v-4h6v4"/>
    <path d="M8 6h.01"/>
    <path d="M16 6h.01"/>
    <path d="M12 6h.01"/>
    <path d="M12 10h.01"/>
    <path d="M12 14h.01"/>
    <path d="M16 10h.01"/>
    <path d="M16 14h.01"/>
    <path d="M8 10h.01"/>
    <path d="M8 14h.01"/>
  </svg>
);

export const CameraIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-3l-2.5-3z"/>
    <circle cx="12" cy="13" r="3"/>
  </svg>
);

export const TagIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M12 2H2v10l9.29 9.29c.94.94 2.48.94 3.42 0l6.58-6.58c.94-.94.94-2.48 0-3.42L12 2Z"/>
    <path d="M7 7h.01"/>
  </svg>
);

export const ConstructionSiteIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 280 200" className={className}>
    {/* Sky background */}
    <rect x="0" y="0" width="280" height="140" fill="#E8F4F8" />
    {/* Ground */}
    <rect x="0" y="140" width="280" height="60" fill="#FFD93D" stroke="#2D3436" strokeWidth="2" />

    {/* Crane */}
    <rect x="30" y="40" width="8" height="100" fill="#FF6B6B" stroke="#2D3436" strokeWidth="2" />
    <rect x="20" y="35" width="100" height="8" fill="#FF6B6B" stroke="#2D3436" strokeWidth="2" />
    <path d="M38 43 L38 35 L110 35" stroke="#2D3436" strokeWidth="2" fill="none" />
    <path d="M100 43 V80" stroke="#2D3436" strokeWidth="2" strokeDasharray="4,4" />
    <rect x="92" y="75" width="16" height="12" fill="#FFD93D" stroke="#2D3436" strokeWidth="2" />

    {/* Building under construction */}
    <rect x="140" y="60" width="100" height="80" fill="white" stroke="#2D3436" strokeWidth="3" />
    <rect x="155" y="75" width="20" height="25" fill="#29AB87" stroke="#2D3436" strokeWidth="2" />
    <rect x="195" y="75" width="20" height="25" fill="#29AB87" stroke="#2D3436" strokeWidth="2" />
    <rect x="155" y="110" width="20" height="25" fill="#29AB87" stroke="#2D3436" strokeWidth="2" />
    <rect x="195" y="110" width="20" height="25" fill="#29AB87" stroke="#2D3436" strokeWidth="2" />
    {/* Scaffolding lines */}
    <path d="M140 90 H240 M140 120 H240" stroke="#2D3436" strokeWidth="1" strokeDasharray="5,3" />

    {/* Hard hat on ground */}
    <ellipse cx="70" cy="155" rx="15" ry="5" fill="#FFD93D" stroke="#2D3436" strokeWidth="2" />
    <path d="M55 155 Q55 145 70 145 Q85 145 85 155" fill="#FFD93D" stroke="#2D3436" strokeWidth="2" />

    {/* Scattered photos/documents */}
    <rect x="180" y="150" width="25" height="18" fill="white" stroke="#2D3436" strokeWidth="2" transform="rotate(-10 192 159)" />
    <rect x="210" y="155" width="25" height="18" fill="white" stroke="#2D3436" strokeWidth="2" transform="rotate(15 222 164)" />
    <rect x="195" y="160" width="25" height="18" fill="#FF6B6B" stroke="#2D3436" strokeWidth="2" transform="rotate(5 207 169)" />
  </svg>
);

export const OrganizedFilesIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 280 200" className={className}>
    {/* Background */}
    <rect x="0" y="0" width="280" height="200" fill="#FAFAF8" />

    {/* Folder structure */}
    <rect x="30" y="30" width="220" height="150" rx="8" fill="white" stroke="#2D3436" strokeWidth="3" />

    {/* Main folder */}
    <path d="M50 55 h40 l5 8 h115 v15 h-165 v-18 a5 5 0 0 1 5 -5" fill="#29AB87" stroke="#2D3436" strokeWidth="2" />
    <text x="60" y="72" fontFamily="Quicksand" fontWeight="bold" fontSize="10" fill="white">Baustelle-A</text>

    {/* Subfolders */}
    <g transform="translate(70, 90)">
      <rect x="0" y="0" width="50" height="35" rx="3" fill="#FFD93D" stroke="#2D3436" strokeWidth="2" />
      <text x="6" y="15" fontFamily="Quicksand" fontWeight="bold" fontSize="7" fill="#2D3436">Fotos</text>
      <text x="6" y="27" fontFamily="Quicksand" fontSize="6" fill="#2D3436">📸 45</text>
    </g>

    <g transform="translate(130, 90)">
      <rect x="0" y="0" width="50" height="35" rx="3" fill="#FF6B6B" stroke="#2D3436" strokeWidth="2" />
      <text x="6" y="15" fontFamily="Quicksand" fontWeight="bold" fontSize="7" fill="white">Pläne</text>
      <text x="6" y="27" fontFamily="Quicksand" fontSize="6" fill="white">📄 12</text>
    </g>

    <g transform="translate(190, 90)">
      <rect x="0" y="0" width="50" height="35" rx="3" fill="#29AB87" stroke="#2D3436" strokeWidth="2" />
      <text x="4" y="15" fontFamily="Quicksand" fontWeight="bold" fontSize="7" fill="white">Berichte</text>
      <text x="6" y="27" fontFamily="Quicksand" fontSize="6" fill="white">📋 8</text>
    </g>

    {/* Date sorted indicator */}
    <g transform="translate(70, 135)">
      <rect x="0" y="0" width="170" height="25" rx="3" fill="#E8F4F8" stroke="#2D3436" strokeWidth="1" />
      <text x="10" y="16" fontFamily="Quicksand" fontWeight="bold" fontSize="8" fill="#2D3436">✨ Automatisch nach Datum & Typ sortiert</text>
    </g>

    {/* Checkmark */}
    <circle cx="250" cy="50" r="18" fill="#29AB87" stroke="#2D3436" strokeWidth="2" />
    <path d="M242 50 L248 56 L260 44" stroke="white" strokeWidth="3" fill="none" strokeLinecap="round" />
  </svg>
);

export const RealEstateIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 120 100" className={className}>
    {/* House */}
    <path d="M60 15 L100 45 L100 90 L20 90 L20 45 Z" fill="white" stroke="#2D3436" strokeWidth="3" />
    <path d="M60 15 L15 50 M60 15 L105 50" stroke="#2D3436" strokeWidth="3" strokeLinecap="round" />
    {/* Roof */}
    <path d="M60 15 L100 45 L20 45 Z" fill="#FF6B6B" stroke="#2D3436" strokeWidth="2" />
    {/* Door */}
    <rect x="50" y="60" width="20" height="30" fill="#29AB87" stroke="#2D3436" strokeWidth="2" />
    <circle cx="65" cy="77" r="2" fill="#FFD93D" />
    {/* Windows */}
    <rect x="28" y="55" width="15" height="15" fill="#FFD93D" stroke="#2D3436" strokeWidth="2" />
    <rect x="77" y="55" width="15" height="15" fill="#FFD93D" stroke="#2D3436" strokeWidth="2" />
    <path d="M35.5 55 V70 M28 62.5 H43" stroke="#2D3436" strokeWidth="1" />
    <path d="M84.5 55 V70 M77 62.5 H92" stroke="#2D3436" strokeWidth="1" />
  </svg>
);

export const DocumentStackIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/>
    <path d="M8 7h6"/>
    <path d="M8 11h8"/>
  </svg>
);

// More decorative illustrations

export const LaptopIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 120 80" className={className} fill="none">
    {/* Screen */}
    <rect x="15" y="5" width="90" height="55" rx="4" fill="#29AB87" stroke="#2D3436" strokeWidth="3"/>
    {/* Screen content */}
    <rect x="22" y="12" width="76" height="41" fill="white" stroke="#2D3436" strokeWidth="1"/>
    <rect x="28" y="18" width="30" height="4" fill="#FFD93D"/>
    <rect x="28" y="26" width="50" height="3" fill="#E8E8E8"/>
    <rect x="28" y="32" width="45" height="3" fill="#E8E8E8"/>
    <rect x="28" y="38" width="55" height="3" fill="#E8E8E8"/>
    {/* Keyboard base */}
    <path d="M5 60 L15 60 L15 55 L105 55 L105 60 L115 60 L115 70 L5 70 Z" fill="#2D3436" stroke="#2D3436" strokeWidth="2"/>
    <ellipse cx="60" cy="65" rx="20" ry="3" fill="#3D4446"/>
  </svg>
);

export const ExcavatorIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 140 100" className={className} fill="none">
    {/* Tracks */}
    <ellipse cx="45" cy="85" rx="35" ry="12" fill="#2D3436" stroke="#2D3436" strokeWidth="2"/>
    <ellipse cx="45" cy="85" rx="28" ry="8" fill="#FFD93D" stroke="#2D3436" strokeWidth="2"/>
    {/* Body */}
    <rect x="20" y="50" width="60" height="30" rx="4" fill="#FFD93D" stroke="#2D3436" strokeWidth="3"/>
    {/* Cabin */}
    <rect x="55" y="35" width="25" height="20" rx="2" fill="#29AB87" stroke="#2D3436" strokeWidth="2"/>
    <rect x="60" y="40" width="15" height="10" fill="white" stroke="#2D3436" strokeWidth="1"/>
    {/* Arm */}
    <path d="M20 55 L-5 40 L-15 55 L-5 60 Z" fill="#FFD93D" stroke="#2D3436" strokeWidth="2"/>
    <path d="M-5 40 L-25 20 L-35 25 L-15 45 Z" fill="#FFD93D" stroke="#2D3436" strokeWidth="2"/>
    {/* Bucket */}
    <path d="M-25 20 L-40 25 L-45 15 L-30 8 Z" fill="#2D3436" stroke="#2D3436" strokeWidth="2"/>
    {/* Exhaust */}
    <rect x="70" y="30" width="5" height="10" fill="#2D3436"/>
  </svg>
);

export const ConstructionWorkerIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 80 120" className={className} fill="none">
    {/* Hard hat */}
    <ellipse cx="40" cy="22" rx="22" ry="8" fill="#FFD93D" stroke="#2D3436" strokeWidth="2"/>
    <path d="M18 22 Q18 10 40 10 Q62 10 62 22" fill="#FFD93D" stroke="#2D3436" strokeWidth="2"/>
    {/* Face */}
    <circle cx="40" cy="38" r="15" fill="#FFDAB9" stroke="#2D3436" strokeWidth="2"/>
    {/* Eyes */}
    <circle cx="35" cy="36" r="2" fill="#2D3436"/>
    <circle cx="45" cy="36" r="2" fill="#2D3436"/>
    {/* Smile */}
    <path d="M35 44 Q40 48 45 44" stroke="#2D3436" strokeWidth="2" fill="none"/>
    {/* Body/Vest */}
    <path d="M25 53 L25 90 L55 90 L55 53 Q40 60 25 53" fill="#FF6B6B" stroke="#2D3436" strokeWidth="2"/>
    {/* Vest stripes */}
    <path d="M25 65 L55 65" stroke="#FFD93D" strokeWidth="3"/>
    <path d="M25 75 L55 75" stroke="#FFD93D" strokeWidth="3"/>
    {/* Arms */}
    <path d="M25 55 L15 75" stroke="#FFDAB9" strokeWidth="8" strokeLinecap="round"/>
    <path d="M55 55 L65 75" stroke="#FFDAB9" strokeWidth="8" strokeLinecap="round"/>
    {/* Clipboard */}
    <rect x="60" y="68" width="15" height="20" fill="white" stroke="#2D3436" strokeWidth="2"/>
    <path d="M63 73 h9 M63 78 h7 M63 83 h8" stroke="#2D3436" strokeWidth="1"/>
    {/* Legs */}
    <rect x="30" y="90" width="8" height="25" fill="#2D3436"/>
    <rect x="42" y="90" width="8" height="25" fill="#2D3436"/>
  </svg>
);

export const WomanWithLaptopIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 100 120" className={className} fill="none">
    {/* Hair */}
    <path d="M30 25 Q30 5 50 5 Q70 5 70 25 Q75 40 70 50 L65 45 L60 50 L55 45 L50 55 L45 45 L40 50 L35 45 L30 50 Q25 40 30 25" fill="#2D3436" stroke="#2D3436" strokeWidth="2"/>
    {/* Face */}
    <circle cx="50" cy="40" r="18" fill="#FFDAB9" stroke="#2D3436" strokeWidth="2"/>
    {/* Eyes */}
    <circle cx="44" cy="38" r="2" fill="#2D3436"/>
    <circle cx="56" cy="38" r="2" fill="#2D3436"/>
    {/* Big smile */}
    <path d="M42 47 Q50 55 58 47" stroke="#2D3436" strokeWidth="2" fill="none"/>
    {/* Blush */}
    <ellipse cx="38" cy="44" rx="3" ry="2" fill="#FF6B6B" opacity="0.5"/>
    <ellipse cx="62" cy="44" rx="3" ry="2" fill="#FF6B6B" opacity="0.5"/>
    {/* Body/Shirt */}
    <path d="M32 58 L32 95 L68 95 L68 58 Q50 68 32 58" fill="#29AB87" stroke="#2D3436" strokeWidth="2"/>
    {/* Arms on desk */}
    <path d="M32 60 L20 80 L25 95" stroke="#FFDAB9" strokeWidth="8" strokeLinecap="round"/>
    <path d="M68 60 L80 80 L75 95" stroke="#FFDAB9" strokeWidth="8" strokeLinecap="round"/>
    {/* Laptop */}
    <rect x="15" y="88" width="70" height="5" fill="#2D3436" stroke="#2D3436" strokeWidth="2"/>
    <rect x="25" y="70" width="50" height="30" fill="#2D3436" stroke="#2D3436" strokeWidth="2"/>
    <rect x="28" y="73" width="44" height="24" fill="#29AB87"/>
    {/* Screen glow */}
    <rect x="32" y="78" width="20" height="3" fill="#FFD93D"/>
    <rect x="32" y="84" width="30" height="2" fill="white" opacity="0.5"/>
    <rect x="32" y="88" width="25" height="2" fill="white" opacity="0.5"/>
  </svg>
);

export const DocumentsIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 80 100" className={className} fill="none">
    {/* Back document */}
    <rect x="15" y="5" width="50" height="65" fill="white" stroke="#2D3436" strokeWidth="2" transform="rotate(8 40 37)"/>
    {/* Middle document */}
    <rect x="10" y="10" width="50" height="65" fill="#FFD93D" stroke="#2D3436" strokeWidth="2" transform="rotate(-5 35 42)"/>
    {/* Front document */}
    <rect x="12" y="15" width="50" height="65" fill="white" stroke="#2D3436" strokeWidth="3"/>
    {/* Lines on front doc */}
    <path d="M20 28 h30" stroke="#2D3436" strokeWidth="2"/>
    <path d="M20 38 h25" stroke="#E8E8E8" strokeWidth="2"/>
    <path d="M20 46 h28" stroke="#E8E8E8" strokeWidth="2"/>
    <path d="M20 54 h20" stroke="#E8E8E8" strokeWidth="2"/>
    <path d="M20 62 h26" stroke="#E8E8E8" strokeWidth="2"/>
    {/* Checkmark */}
    <circle cx="55" cy="70" r="12" fill="#29AB87" stroke="#2D3436" strokeWidth="2"/>
    <path d="M50 70 L54 74 L62 64" stroke="white" strokeWidth="3" fill="none"/>
  </svg>
);

export const FilesImageIllustration = ({className}: {className?: string}) => (
  <svg viewBox="0 0 80 80" className={className} fill="none">
    {/* Image frame */}
    <rect x="5" y="5" width="70" height="55" fill="white" stroke="#2D3436" strokeWidth="3"/>
    {/* Mountain scene */}
    <path d="M5 45 L25 25 L45 45 L55 35 L75 50 L75 60 L5 60 Z" fill="#29AB87"/>
    {/* Sun */}
    <circle cx="60" cy="20" r="10" fill="#FFD93D" stroke="#2D3436" strokeWidth="2"/>
    {/* Image corner fold */}
    <path d="M75 5 L75 15 L65 5 Z" fill="#E8E8E8" stroke="#2D3436" strokeWidth="1"/>
    {/* Label underneath */}
    <rect x="15" y="65" width="50" height="12" rx="2" fill="#FF6B6B" stroke="#2D3436" strokeWidth="2"/>
    <text x="40" y="74" fontFamily="Quicksand" fontWeight="bold" fontSize="7" fill="white" textAnchor="middle">IMG_2024.jpg</text>
  </svg>
);

export const BookIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/>
  </svg>
);

export const MailIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <rect width="20" height="16" x="2" y="4" rx="2"/>
    <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>
  </svg>
);

export const TradesIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className={className}>
    <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>
  </svg>
);

export const QuoteIcon = ({ className }: { className?: string }) => (
  <svg width="40" height="40" viewBox="0 0 24 24" fill="currentColor" className={className}>
    <path d="M11 7.5C11 10.5376 8.53757 13 5.5 13C5.21635 13 4.93945 12.9717 4.67186 12.9178C4.24903 12.8336 4 12.4247 4 12V11.0897C4 10.6437 4.22077 10.2356 4.57657 9.97659C5.59249 9.23586 6.5 8.20299 6.5 7C6.5 5.067 5.433 4 4 4V3C6.76142 3 9 5.23858 9 8V8.5H11V7.5ZM20 7.5C20 10.5376 17.5376 13 14.5 13C14.2163 13 13.9395 12.9717 13.6719 12.9178C13.249 12.8336 13 12.4247 13 12V11.0897C13 10.6437 13.2208 10.2356 13.5766 9.97659C14.5925 9.23586 15.5 8.20299 15.5 7C15.5 5.067 14.433 4 13 4V3C15.7614 3 18 5.23858 18 8V8.5H20V7.5Z"/>
  </svg>
);
