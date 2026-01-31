import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://nlvlwrhayrvberdyjgjx.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sdmx3cmhheXJ2YmVyZHlqZ2p4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg2MDIwMDksImV4cCI6MjA4NDE3ODAwOX0.qKpkkOI2BC6yww8ZV7VFl6tMLNx_VyZifUPPFAciyws';

if (!import.meta.env.VITE_SUPABASE_URL || !import.meta.env.VITE_SUPABASE_ANON_KEY) {
  console.warn('Supabase env vars not found, using fallback values');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Types for our database
export interface Profile {
  id: string;
  email: string;
  full_name: string | null;
  credits_total: number;
  credits_used: number;
  credits_remaining: number;
  created_at: string;
  updated_at: string;
}

export interface UserAnalytics {
  user_id: string;
  credits_total: number;
  credits_used: number;
  credits_remaining: number;
  total_files_organized: number;
  total_folders_created: number;
  total_sessions: number;
  files_this_month: number;
  sessions_this_month: number;
  last_organization_at: string | null;
  total_purchases: number;
  total_spent_cents: number;
}
