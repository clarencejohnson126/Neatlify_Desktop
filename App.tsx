
import React, { useState, useEffect } from 'react';
import { AuthProvider } from './contexts/AuthContext';
import LandingPage from './LandingPage';
import SuccessPage from './SuccessPage';
import AccountPage from './AccountPage';
import ConstructionPage from './ConstructionPage';
import ImpressumPage from './ImpressumPage';
import PrivacyPage from './PrivacyPage';

const AppContent: React.FC = () => {
  const [currentPath, setCurrentPath] = useState(window.location.hash);

  useEffect(() => {
    const handleHashChange = () => {
      setCurrentPath(window.location.hash);
    };

    window.addEventListener('hashchange', handleHashChange);
    return () => window.removeEventListener('hashchange', handleHashChange);
  }, []);

  // Simple hash-based router
  if (currentPath.startsWith('#/success')) {
    return <SuccessPage />;
  }

  if (currentPath.startsWith('#/account')) {
    return <AccountPage />;
  }

  if (currentPath.startsWith('#/construction')) {
    return <ConstructionPage />;
  }

  if (currentPath.startsWith('#/impressum') || currentPath.startsWith('#/terms')) {
    return <ImpressumPage />;
  }

  if (currentPath.startsWith('#/privacy')) {
    return <PrivacyPage />;
  }

  return <LandingPage />;
};

const App: React.FC = () => {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
};

export default App;
