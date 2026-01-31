
import React, { useState, useEffect } from 'react';
import { AuthProvider } from './contexts/AuthContext';
import LandingPage from './LandingPage';
import SuccessPage from './SuccessPage';
import AccountPage from './AccountPage';

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
