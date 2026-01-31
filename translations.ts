
export type Language = 'EN' | 'DE';

export const translations = {
  EN: {
    nav: {
      features: "Features",
      howItWorks: "How it works",
      professionals: "For Pros",
      pricing: "Pricing",
      download: "Download"
    },
    hero: {
      headline: "Organize your files intelligently",
      subheadline: "Neatlify understands what's actually IN your files - not just their names. Drop a messy folder, get perfect organization.",
      cta: "Download for macOS",
      secondary: "See how it works",
      requirements: "Requires macOS 13 or later",
      version: "Version 1.0.0",
      badges: {
        personal: "For Everyone",
        business: "For Professionals"
      },
      useCases: "Perfect for photos, documents, receipts, screenshots — and construction site documentation"
    },
    how: {
      title: "How It Works",
      step1: {
        title: "Select a folder",
        desc: "Point Neatlify to any messy folder on your Mac."
      },
      step2: {
        title: "Tell Neatlify what to do",
        desc: "Describe how you want files organized — in plain English.",
        example: '"Sort my construction photos by trade and date"'
      },
      step3: {
        title: "Content is analyzed",
        desc: "We look inside images, PDFs, and docs to understand them."
      },
      step4: {
        title: "Files organized instantly",
        desc: "Get a clean, logical folder structure in seconds."
      }
    },
    features: {
      images: {
        title: "Understands images",
        desc: "Neatlify sees what's in photos, screenshots, and diagrams.",
        backTitle: "Deep Image Analysis",
        backDesc: "Neatlify analyzes every image to understand its content - people, places, objects, text, diagrams. It recognizes construction progress, product photos, receipts, ID documents, and much more.",
        backList: ["Face & object recognition", "Text extraction (OCR)", "Scene understanding", "Diagram interpretation"]
      },
      docs: {
        title: "Reads documents",
        desc: "Analyzes PDFs, Word docs, and text files deeply.",
        backTitle: "Smart Document Processing",
        backDesc: "From contracts to invoices, from reports to emails - Neatlify reads and understands the content of your documents to categorize them intelligently.",
        backList: ["PDF text extraction", "Invoice detection", "Contract analysis", "Report categorization"]
      },
      categories: {
        title: "Smart categories",
        desc: "Creates logical folder structures automatically.",
        backTitle: "Intelligent Organization",
        backDesc: "No more manual folder creation. Neatlify creates a logical hierarchy based on content type, date, project, and relationships between files.",
        backList: ["Auto folder creation", "Date-based sorting", "Project grouping", "Duplicate detection"]
      },
      privacy: {
        title: "Privacy first",
        desc: "Files never leave your Mac, only descriptions are sent.",
        backTitle: "Your Data Stays Yours",
        backDesc: "We never upload your actual files. Only text descriptions are sent for analysis. Your sensitive documents remain on your Mac.",
        backList: ["Local processing", "No file uploads", "Encrypted descriptions", "GDPR compliant"]
      },
      undo: {
        title: "Undo anytime",
        desc: "Full history of all moves, one-click restore if needed.",
        backTitle: "Complete Peace of Mind",
        backDesc: "Every file move is logged. Made a mistake? One click restores everything to exactly how it was. We keep history for 30 days.",
        backList: ["Full move history", "One-click undo", "30-day retention", "Selective restore"]
      },
      offline: {
        title: "Works offline",
        desc: "After initial setup, no internet required for basics.",
        backTitle: "Work Anywhere",
        backDesc: "Basic organization features work without internet. Smart features require connection, but your organized files are always accessible.",
        backList: ["Offline file access", "Local organization", "Sync when online", "No subscription needed"]
      }
    },
    professionals: {
      title: "Built for Construction & Real Estate",
      subtitle: "Thousands of site photos, blueprints, and reports? Neatlify organizes them automatically — by date, trade, and project.",
      useCases: [
        {
          title: "Site Documentation",
          desc: "Recognizes construction phases, defects, and progress.",
          tag: "Documentation",
          backTitle: "Complete Site History",
          backDesc: "Every photo automatically tagged with date, location, and construction phase. Detects defects, progress milestones, and safety issues. Generate reports with one click.",
          backList: ["Auto date/time tagging", "Progress tracking", "Defect detection", "Report generation"]
        },
        {
          title: "Auto-Labeling",
          desc: "No more 'IMG_4523.jpg' — files renamed by content.",
          tag: "Labeling",
          backTitle: "Meaningful File Names",
          backDesc: "Transform cryptic camera names into descriptive labels like 'Kitchen_Electrical_2024-01-15.jpg'. Searchable, sortable, professional.",
          backList: ["Content-based naming", "Date integration", "Trade/location tags", "Batch renaming"]
        },
        {
          title: "Blueprint Management",
          desc: "Separate floor plans, electrical, and structural drawings.",
          tag: "Plans",
          backTitle: "Drawing Organization",
          backDesc: "Distinguishes between architectural, structural, electrical, plumbing, and HVAC drawings. Version control included.",
          backList: ["Drawing type detection", "Version tracking", "Revision history", "Quick search"]
        },
        {
          title: "Property Portfolios",
          desc: "Real estate agents: organize by property.",
          tag: "Real Estate",
          backTitle: "Property-Centric Organization",
          backDesc: "Each property gets its own folder with photos, contracts, inspection reports, and correspondence. Perfect for agents managing multiple listings.",
          backList: ["Per-property folders", "Document grouping", "Photo galleries", "Client-ready exports"]
        }
      ],
      trades: {
        title: "Organize by Trade (Gewerke)",
        subtitle: "Automatically sort files by trade — essential for construction projects",
        list: ["Electrical", "Plumbing", "HVAC", "Structural", "Roofing", "Painting", "Flooring", "Masonry"]
      },
      cta: "See Pricing",
      stats: {
        time: "10+ hours",
        timeLabel: "saved per project",
        files: "50,000+",
        filesLabel: "files organized daily"
      }
    },
    // NEW SECTIONS
    testimonials: {
      title: "Loved by Professionals",
      subtitle: "See what our users say about Neatlify",
      items: [
        {
          quote: "Finally, I can find that one photo from 6 months ago in seconds. Game changer for site documentation.",
          author: "Michael K.",
          role: "Site Manager, Munich",
          company: "Bauhaus Construction"
        },
        {
          quote: "We used to spend hours renaming and sorting photos. Now it's automatic. Our team loves it.",
          author: "Sarah L.",
          role: "Project Coordinator",
          company: "Alpine Builders"
        },
        {
          quote: "The trade-based organization is exactly what we needed. Every electrician photo in one place.",
          author: "Thomas B.",
          role: "Construction Manager",
          company: "TB Engineering"
        }
      ]
    },
    useCasesSection: {
      title: "Perfect for Every Workflow",
      subtitle: "From personal photo libraries to enterprise document management",
      cases: [
        {
          title: "Photographers",
          desc: "Sort thousands of photos by event, subject, and date automatically",
          icon: "camera"
        },
        {
          title: "Architects",
          desc: "Organize drawings, renders, and project files by phase",
          icon: "building"
        },
        {
          title: "Contractors",
          desc: "Keep site photos, permits, and reports perfectly organized",
          icon: "hardhat"
        },
        {
          title: "Real Estate",
          desc: "Manage property listings, photos, and documents efficiently",
          icon: "house"
        },
        {
          title: "Students",
          desc: "Organize lecture notes, papers, and research materials",
          icon: "book"
        },
        {
          title: "Everyone",
          desc: "Finally tame that chaotic Downloads folder",
          icon: "folder"
        }
      ]
    },
    howAiWorks: {
      title: "How It Works Under the Hood",
      subtitle: "Smart technology for understanding your files",
      steps: [
        {
          title: "1. File Analysis",
          desc: "Each file is analyzed locally. Images are described, documents are summarized, PDFs are read."
        },
        {
          title: "2. Content Understanding",
          desc: "Descriptions (never your actual files) are processed to determine the best organization."
        },
        {
          title: "3. Smart Sorting",
          desc: "Files are moved into a logical folder structure based on content, not just file names."
        }
      ],
      privacy: "Your files never leave your Mac. Only text descriptions are sent for processing.",
      badge: "Smart Technology"
    },
    faq: {
      title: "Frequently Asked Questions",
      items: [
        {
          q: "Is my data safe?",
          a: "Absolutely. Your files never leave your Mac. We only send text descriptions for analysis. No images, no documents, no personal data."
        },
        {
          q: "What file types are supported?",
          a: "Images (JPG, PNG, HEIC, RAW), Documents (PDF, DOCX, TXT), and more. We're constantly adding new formats."
        },
        {
          q: "Can I undo changes?",
          a: "Yes! Every move is logged and can be undone with one click. We keep your history for 30 days."
        },
        {
          q: "Do I need internet?",
          a: "Analysis requires internet, but once organized, your files work offline. Basic features work without connection."
        },
        {
          q: "How are credits calculated?",
          a: "One credit = one file analyzed and organized. Subfolders and already-organized files don't count."
        },
        {
          q: "Is there a free trial?",
          a: "Yes! Your first 100 files are free, no credit card required. Test it on your messiest folder."
        }
      ]
    },
    finalCta: {
      title: "Ready to Get Organized?",
      subtitle: "Download Neatlify and organize your first 100 files for free",
      cta: "Download for macOS",
      secondary: "View Pricing",
      trust: "Trusted by 1,000+ professionals"
    },
    pricing: {
      title: "Pricing",
      starter: {
        name: "Starter",
        price: "€5",
        files: "100 files",
        rate: "€0.05 per file",
        tag: "Perfect for trying out"
      },
      pro: {
        name: "Pro",
        price: "€30",
        files: "1,000 files",
        rate: "€0.03 per file",
        tag: "Best for regular use",
        badge: "Save 40%"
      },
      business: {
        name: "Business",
        price: "€200",
        files: "10,000 files",
        rate: "€0.02 per file",
        tag: "For power users",
        badge: "Save 60%"
      },
      enterprise: {
        name: "Enterprise",
        price: "Contact Us",
        files: "Unlimited files",
        rate: "Custom pricing",
        tag: "For teams and organizations"
      },
      buy: "Buy Now",
      contact: "Contact Us",
      free: "🎁 First 100 files free - no credit card required"
    },
    footer: {
      privacy: "Privacy Policy",
      terms: "Terms of Service",
      support: "Support",
      rights: "© 2025 Neatlify. All rights reserved."
    },
    success: {
      title: "Payment Successful!",
      subtitle: "Redirecting you to the app...",
      instructions: "If the app didn't open automatically:",
      step1: "1. Open Neatlify",
      step2: "2. Go to Settings → Subscription",
      step3: "3. Click 'Verify Payment'",
      step4: "4. Paste this code:",
      copy: "Copy Session ID",
      copied: "Copied!"
    }
  },
  DE: {
    nav: {
      features: "Funktionen",
      howItWorks: "Funktionsweise",
      professionals: "Für Profis",
      pricing: "Preise",
      download: "Download"
    },
    hero: {
      headline: "Organisiere deine Dateien intelligent",
      subheadline: "Neatlify versteht, was wirklich IN deinen Dateien ist - nicht nur deren Namen. Ein Klick, perfekte Ordnung.",
      cta: "Download für macOS",
      secondary: "Wie es funktioniert",
      requirements: "Benötigt macOS 13 oder neuer",
      version: "Version 1.0.0",
      badges: {
        personal: "Für Alle",
        business: "Für Profis"
      },
      useCases: "Perfekt für Fotos, Dokumente, Belege, Screenshots — und Baustellendokumentation"
    },
    how: {
      title: "So funktioniert's",
      step1: {
        title: "Wähle einen Ordner",
        desc: "Wähle einen unordentlichen Ordner auf deinem Mac aus."
      },
      step2: {
        title: "Sag Neatlify was zu tun ist",
        desc: "Beschreibe, wie du deine Dateien organisiert haben möchtest — in normalem Deutsch.",
        example: '"Sortiere meine Baustellenfotos nach Gewerk und Datum"'
      },
      step3: {
        title: "Inhalte werden analysiert",
        desc: "Wir scannen Bilder, PDFs und Dokumente für echtes Verständnis."
      },
      step4: {
        title: "Dateien sofort organisiert",
        desc: "Erhalte in Sekunden eine saubere Ordnerstruktur."
      }
    },
    features: {
      images: {
        title: "Versteht Bilder",
        desc: "Neatlify erkennt Inhalte in Fotos, Screenshots und Diagrammen.",
        backTitle: "Tiefe Bildanalyse",
        backDesc: "Neatlify analysiert jedes Bild - Personen, Orte, Objekte, Text, Diagramme. Erkennt Baufortschritt, Produktfotos, Belege, Ausweise und vieles mehr.",
        backList: ["Gesichts- & Objekterkennung", "Texterkennung (OCR)", "Szenenverständnis", "Diagramm-Interpretation"]
      },
      docs: {
        title: "Liest Dokumente",
        desc: "Analysiert PDFs, Word-Dokumente und Textdateien.",
        backTitle: "Intelligente Dokumentverarbeitung",
        backDesc: "Von Verträgen bis Rechnungen, von Berichten bis E-Mails - Neatlify liest und versteht den Inhalt deiner Dokumente.",
        backList: ["PDF-Textextraktion", "Rechnungserkennung", "Vertragsanalyse", "Berichtskategorisierung"]
      },
      categories: {
        title: "Smarte Kategorien",
        desc: "Erstellt automatisch logische Ordnerstrukturen.",
        backTitle: "Intelligente Organisation",
        backDesc: "Keine manuelle Ordnererstellung mehr. Neatlify erstellt eine logische Hierarchie basierend auf Inhaltstyp, Datum, Projekt und Beziehungen.",
        backList: ["Auto-Ordnererstellung", "Datumsbasierte Sortierung", "Projektgruppierung", "Duplikaterkennung"]
      },
      privacy: {
        title: "Datenschutz zuerst",
        desc: "Dateien verlassen nie deinen Mac, nur Beschreibungen werden gesendet.",
        backTitle: "Deine Daten bleiben deine",
        backDesc: "Wir laden niemals deine Dateien hoch. Nur Textbeschreibungen werden zur Analyse gesendet. Sensible Dokumente bleiben auf deinem Mac.",
        backList: ["Lokale Verarbeitung", "Kein Datei-Upload", "Verschlüsselte Beschreibungen", "DSGVO-konform"]
      },
      undo: {
        title: "Jederzeit rückgängig",
        desc: "Voller Verlauf aller Verschiebungen, ein Klick genügt.",
        backTitle: "Absolute Sicherheit",
        backDesc: "Jede Dateiverschiebung wird protokolliert. Fehler gemacht? Ein Klick stellt alles wieder her. 30 Tage Verlauf.",
        backList: ["Vollständiger Verlauf", "Ein-Klick-Rückgängig", "30 Tage Aufbewahrung", "Selektive Wiederherstellung"]
      },
      offline: {
        title: "Funktioniert offline",
        desc: "Grundfunktionen nach dem Setup auch ohne Internet.",
        backTitle: "Überall arbeiten",
        backDesc: "Basis-Organisationsfunktionen ohne Internet. Smarte Funktionen benötigen Verbindung, aber organisierte Dateien sind immer zugänglich.",
        backList: ["Offline-Dateizugriff", "Lokale Organisation", "Sync bei Verbindung", "Kein Abo nötig"]
      }
    },
    professionals: {
      title: "Für Bau & Immobilien",
      subtitle: "Tausende Baustellenfotos, Pläne und Berichte? Neatlify organisiert sie automatisch — nach Datum, Gewerk und Projekt.",
      useCases: [
        {
          title: "Baustellendokumentation",
          desc: "Erkennt Bauphasen, Mängel und Fortschritt.",
          tag: "Dokumentation",
          backTitle: "Komplette Bauhistorie",
          backDesc: "Jedes Foto automatisch mit Datum, Ort und Bauphase versehen. Erkennt Mängel, Meilensteine und Sicherheitsprobleme. Berichte mit einem Klick.",
          backList: ["Auto Datum/Zeit-Tagging", "Fortschrittsverfolgung", "Mängelerkennung", "Berichtsgenerierung"]
        },
        {
          title: "Auto-Beschriftung",
          desc: "Schluss mit 'IMG_4523.jpg' — Dateien nach Inhalt benannt.",
          tag: "Beschriftung",
          backTitle: "Aussagekräftige Dateinamen",
          backDesc: "Kryptische Kameranamen werden zu beschreibenden Labels wie 'Kueche_Elektro_2024-01-15.jpg'. Suchbar, sortierbar, professionell.",
          backList: ["Inhaltsbasierte Benennung", "Datumsintegration", "Gewerk-/Ort-Tags", "Stapelumbenennung"]
        },
        {
          title: "Planverwaltung",
          desc: "Grundrisse, Elektro- und Statikpläne getrennt.",
          tag: "Pläne",
          backTitle: "Zeichnungsorganisation",
          backDesc: "Unterscheidet zwischen Architektur-, Statik-, Elektro-, Sanitär- und HLK-Zeichnungen. Versionskontrolle inklusive.",
          backList: ["Zeichnungstyp-Erkennung", "Versionsverfolgung", "Revisionshistorie", "Schnellsuche"]
        },
        {
          title: "Immobilien-Portfolios",
          desc: "Makler: Organisation nach Objekten.",
          tag: "Immobilien",
          backTitle: "Objektzentrierte Organisation",
          backDesc: "Jedes Objekt erhält eigenen Ordner mit Fotos, Verträgen, Gutachten und Korrespondenz. Perfekt für Makler mit vielen Listings.",
          backList: ["Pro-Objekt-Ordner", "Dokumentengruppierung", "Fotogalerien", "Kundenfertige Exporte"]
        }
      ],
      trades: {
        title: "Organisation nach Gewerk",
        subtitle: "Automatische Sortierung nach Gewerk — unverzichtbar für Bauprojekte",
        list: ["Elektro", "Sanitär", "Heizung/Klima", "Rohbau", "Dach", "Maler", "Boden", "Maurer"]
      },
      cta: "Zu den Preisen",
      stats: {
        time: "10+ Stunden",
        timeLabel: "gespart pro Projekt",
        files: "50.000+",
        filesLabel: "Dateien täglich organisiert"
      }
    },
    // NEW SECTIONS
    testimonials: {
      title: "Von Profis geliebt",
      subtitle: "Das sagen unsere Nutzer über Neatlify",
      items: [
        {
          quote: "Endlich finde ich das eine Foto von vor 6 Monaten in Sekunden. Ein Gamechanger für die Baudokumentation.",
          author: "Michael K.",
          role: "Bauleiter, München",
          company: "Bauhaus Construction"
        },
        {
          quote: "Früher haben wir Stunden mit Umbenennen und Sortieren verbracht. Jetzt läuft alles automatisch.",
          author: "Sarah L.",
          role: "Projektkoordinatorin",
          company: "Alpine Builders"
        },
        {
          quote: "Die gewerkbasierte Organisation ist genau das, was wir brauchten. Alle Elektrikerfotos an einem Ort.",
          author: "Thomas B.",
          role: "Baumanager",
          company: "TB Engineering"
        }
      ]
    },
    useCasesSection: {
      title: "Perfekt für jeden Workflow",
      subtitle: "Von persönlichen Fotobibliotheken bis zum Enterprise-Dokumentenmanagement",
      cases: [
        {
          title: "Fotografen",
          desc: "Tausende Fotos automatisch nach Event, Motiv und Datum sortieren",
          icon: "camera"
        },
        {
          title: "Architekten",
          desc: "Zeichnungen, Renderings und Projektdateien nach Phase organisieren",
          icon: "building"
        },
        {
          title: "Bauunternehmer",
          desc: "Baustellenfotos, Genehmigungen und Berichte perfekt sortiert",
          icon: "hardhat"
        },
        {
          title: "Immobilien",
          desc: "Objekt-Listings, Fotos und Dokumente effizient verwalten",
          icon: "house"
        },
        {
          title: "Studenten",
          desc: "Vorlesungsnotizen, Arbeiten und Recherchematerial organisieren",
          icon: "book"
        },
        {
          title: "Für Alle",
          desc: "Endlich den chaotischen Downloads-Ordner bändigen",
          icon: "folder"
        }
      ]
    },
    howAiWorks: {
      title: "So funktioniert es im Detail",
      subtitle: "Smarte Technologie zum Verstehen deiner Dateien",
      steps: [
        {
          title: "1. Datei-Analyse",
          desc: "Jede Datei wird lokal analysiert. Bilder beschrieben, Dokumente zusammengefasst, PDFs gelesen."
        },
        {
          title: "2. Inhaltsverständnis",
          desc: "Beschreibungen (nie deine Dateien) werden verarbeitet um die beste Organisation zu bestimmen."
        },
        {
          title: "3. Intelligente Sortierung",
          desc: "Dateien werden nach Inhalt in logische Ordnerstrukturen verschoben — nicht nur nach Namen."
        }
      ],
      privacy: "Deine Dateien verlassen nie deinen Mac. Nur Textbeschreibungen werden zur Verarbeitung gesendet.",
      badge: "Smarte Technologie"
    },
    faq: {
      title: "Häufig gestellte Fragen",
      items: [
        {
          q: "Sind meine Daten sicher?",
          a: "Absolut. Deine Dateien verlassen nie deinen Mac. Es werden nur Textbeschreibungen zur Analyse gesendet. Keine Bilder, keine Dokumente, keine persönlichen Daten."
        },
        {
          q: "Welche Dateitypen werden unterstützt?",
          a: "Bilder (JPG, PNG, HEIC, RAW), Dokumente (PDF, DOCX, TXT) und mehr. Wir fügen ständig neue Formate hinzu."
        },
        {
          q: "Kann ich Änderungen rückgängig machen?",
          a: "Ja! Jede Verschiebung wird protokolliert und kann mit einem Klick rückgängig gemacht werden. 30 Tage Verlauf."
        },
        {
          q: "Brauche ich Internet?",
          a: "Analyse benötigt Internet, aber organisierte Dateien funktionieren offline. Basisfunktionen auch ohne Verbindung."
        },
        {
          q: "Wie werden Credits berechnet?",
          a: "Ein Credit = eine analysierte und organisierte Datei. Unterordner und bereits organisierte Dateien zählen nicht."
        },
        {
          q: "Gibt es eine kostenlose Testversion?",
          a: "Ja! Die ersten 100 Dateien sind kostenlos, keine Kreditkarte nötig. Teste es an deinem chaotischsten Ordner."
        }
      ]
    },
    finalCta: {
      title: "Bereit für Ordnung?",
      subtitle: "Lade Neatlify herunter und organisiere deine ersten 100 Dateien kostenlos",
      cta: "Download für macOS",
      secondary: "Preise ansehen",
      trust: "Vertraut von 1.000+ Profis"
    },
    pricing: {
      title: "Preise",
      starter: {
        name: "Starter",
        price: "€5",
        files: "100 Dateien",
        rate: "€0.05 pro Datei",
        tag: "Perfekt zum Ausprobieren"
      },
      pro: {
        name: "Pro",
        price: "€30",
        files: "1.000 Dateien",
        rate: "€0.03 pro Datei",
        tag: "Ideal für den Alltag",
        badge: "40% sparen"
      },
      business: {
        name: "Business",
        price: "€200",
        files: "10.000 Dateien",
        rate: "€0.02 pro Datei",
        tag: "Für Power-User",
        badge: "60% sparen"
      },
      enterprise: {
        name: "Enterprise",
        price: "Kontaktieren",
        files: "Unbegrenzt",
        rate: "Individuelle Preise",
        tag: "Für Teams und Firmen"
      },
      buy: "Kaufen",
      contact: "Kontakt",
      free: "🎁 Erste 100 Dateien kostenlos - keine Kreditkarte nötig"
    },
    footer: {
      privacy: "Datenschutz",
      terms: "AGB",
      support: "Support",
      rights: "© 2025 Neatlify. Alle Rechte vorbehalten."
    },
    success: {
      title: "Zahlung erfolgreich!",
      subtitle: "Wir leiten dich zur App weiter...",
      instructions: "Falls die App nicht automatisch startet:",
      step1: "1. Öffne Neatlify",
      step2: "2. Gehe zu Einstellungen → Abonnement",
      step3: "3. Klicke auf 'Zahlung verifizieren'",
      step4: "4. Füge diesen Code ein:",
      copy: "Session ID kopieren",
      copied: "Kopiert!"
    }
  }
};
