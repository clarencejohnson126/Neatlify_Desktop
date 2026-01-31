
import React, { useState, useEffect } from 'react';
import LandingPage from './LandingPage';
import SuccessPage from './SuccessPage';

const App: React.FC = () => {
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

  return <LandingPage />;
};

export default App;
