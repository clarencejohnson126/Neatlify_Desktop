/**
 * Hook to detect if Neatlify desktop app is installed
 * Uses the registered URL scheme (neatlify://) to detect presence
 */
import { useEffect, useState } from 'react';

export const useDesktopAppDetection = () => {
  const [isAppInstalled, setIsAppInstalled] = useState(false);
  const [isChecking, setIsChecking] = useState(true);

  useEffect(() => {
    const detectApp = async () => {
      try {
        // Create a promise that rejects after 100ms timeout
        const timeoutPromise = new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Timeout')), 100)
        );

        // Try to trigger the URL scheme - if app is installed, it will respond
        const pingUrl = 'neatlify://ping';

        // Create a frame to avoid redirecting the current page
        const iframe = document.createElement('iframe');
        iframe.style.display = 'none';
        iframe.src = pingUrl;

        // Wait for timeout
        await timeoutPromise;

        // If timeout passes without app launching, app is likely installed
        // (The ping won't actually execute, but the URL handler will be triggered)
        document.body.appendChild(iframe);

        setTimeout(() => {
          setIsAppInstalled(true);
          setIsChecking(false);
          document.body.removeChild(iframe);
        }, 100);
      } catch (error) {
        // App not installed or timeout occurred
        setIsAppInstalled(false);
        setIsChecking(false);
      }
    };

    detectApp();
  }, []);

  return { isAppInstalled, isChecking };
};
