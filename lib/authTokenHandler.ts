/**
 * Handle extraction and formatting of Supabase session tokens for deep linking
 * Generates secure deep links to pass authentication to the desktop app
 */

import { Session, User } from '@supabase/supabase-js';

export interface DeepLinkTokens {
  accessToken: string;
  refreshToken: string;
  userEmail: string;
  expiresAt: number;
  issuedAt: number;
}

/**
 * Extract tokens from Supabase session
 * Returns null if tokens are missing or invalid
 */
export const getSessionTokens = (session: Session | null, user: User | null): DeepLinkTokens | null => {
  if (!session || !user) {
    console.error('No session or user available');
    return null;
  }

  const accessToken = session.access_token;
  const refreshToken = session.refresh_token;
  const userEmail = user.email;

  // Calculate expires_at in seconds (if not provided by Supabase)
  const expiresAt = session.expires_at || Math.floor(Date.now() / 1000) + 3600; // Default 1 hour

  if (!accessToken || !refreshToken || !userEmail) {
    console.error('Missing required token fields', {
      hasAccessToken: !!accessToken,
      hasRefreshToken: !!refreshToken,
      hasEmail: !!userEmail,
    });
    return null;
  }

  return {
    accessToken,
    refreshToken,
    userEmail,
    expiresAt,
    issuedAt: Math.floor(Date.now() / 1000),
  };
};

/**
 * Validate if tokens are actually valid JWT tokens
 * Performs basic JWT structure validation without signature verification
 */
export const validateJWT = (token: string): boolean => {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      console.error('Invalid JWT: wrong number of parts');
      return false;
    }

    // Decode header and payload (without verifying signature)
    const payload = JSON.parse(atob(parts[1]));
    const now = Math.floor(Date.now() / 1000);

    // Check expiration
    if (payload.exp && payload.exp <= now) {
      console.error('Token expired');
      return false;
    }

    // Check issued time (not issued in future)
    if (payload.iat && payload.iat > now) {
      console.error('Token issued in future');
      return false;
    }

    return true;
  } catch (error) {
    console.error('JWT validation error:', error);
    return false;
  }
};

/**
 * Validate email format
 */
export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Generate secure deep link URL for desktop app authentication
 * Includes token validation before generating link
 */
export const generateAuthDeepLink = (tokens: DeepLinkTokens): string | null => {
  // Validate tokens before generating link
  if (!validateJWT(tokens.accessToken)) {
    console.error('Invalid access token');
    return null;
  }

  if (!validateEmail(tokens.userEmail)) {
    console.error('Invalid email format');
    return null;
  }

  // Build deep link with URL parameters
  const params = new URLSearchParams({
    access_token: tokens.accessToken,
    refresh_token: tokens.refreshToken,
    user_email: tokens.userEmail,
    exp: tokens.expiresAt.toString(),
    iat: tokens.issuedAt.toString(),
  });

  const deepLink = `neatlify://auth-callback?${params.toString()}`;

  console.log('Generated deep link for:', tokens.userEmail);
  return deepLink;
};

/**
 * Open the deep link - triggers desktop app to open with auth params
 */
export const openInDesktopApp = (deepLink: string): void => {
  try {
    // Use a hidden iframe to avoid page navigation
    const iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    iframe.src = deepLink;
    document.body.appendChild(iframe);

    // Clean up iframe after a delay
    setTimeout(() => {
      document.body.removeChild(iframe);
    }, 500);

    console.log('Opened desktop app with auth link');
  } catch (error) {
    console.error('Failed to open desktop app:', error);
    throw error;
  }
};

/**
 * Complete flow: Get tokens, validate, generate link, and open app
 */
export const launchDesktopAppWithAuth = (session: Session | null, user: User | null): boolean => {
  try {
    console.log('Launching desktop app with authentication...');

    // Extract tokens
    const tokens = getSessionTokens(session, user);
    if (!tokens) {
      console.error('Failed to extract session tokens');
      return false;
    }

    // Generate deep link
    const deepLink = generateAuthDeepLink(tokens);
    if (!deepLink) {
      console.error('Failed to generate auth deep link');
      return false;
    }

    // Open in desktop app
    openInDesktopApp(deepLink);

    return true;
  } catch (error) {
    console.error('Error launching desktop app:', error);
    return false;
  }
};
