import React, { useEffect, useState } from 'react';
import { useAuth } from './contexts/AuthContext';
import { supabase, UserAnalytics } from './lib/supabase';

const AccountPage: React.FC = () => {
  const { user, loading } = useAuth();
  const [analytics, setAnalytics] = useState<UserAnalytics | null>(null);
  const [freshProfile, setFreshProfile] = useState<any>(null);
  const [loadingData, setLoadingData] = useState(true);

  useEffect(() => {
    if (user) {
      fetchData();
    }
  }, [user]);

  const fetchData = async () => {
    if (!user) return;
    setLoadingData(true);

    // Fetch fresh profile data (not cached)
    const { data: profileData } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (profileData) {
      setFreshProfile(profileData);
    }

    // Fetch analytics
    const { data: analyticsData } = await supabase
      .from('user_analytics')
      .select('*')
      .eq('user_id', user.id)
      .single();

    if (analyticsData) {
      setAnalytics(analyticsData as UserAnalytics);
    }
    setLoadingData(false);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#FAFAF8] flex items-center justify-center">
        <div className="text-xl font-bold">Loading...</div>
      </div>
    );
  }

  if (!user) {
    window.location.hash = '/';
    return null;
  }

  return (
    <div className="min-h-screen bg-[#FAFAF8]">
      {/* Header */}
      <nav className="bg-white border-b-4 border-[#2D3436] py-4">
        <div className="max-w-4xl mx-auto px-6 flex justify-between items-center">
          <a href="#/" className="flex items-center gap-3">
            <div className="w-10 h-10 bg-[#29AB87] sketch-border flex items-center justify-center">
              <span className="text-white font-bold text-xl">N</span>
            </div>
            <span className="text-2xl font-bold text-[#2D3436]">Neatlify</span>
          </a>
          <a
            href="#/"
            className="text-sm font-bold text-[#2D3436] hover:text-[#29AB87] transition-all"
          >
            Back to Home
          </a>
        </div>
      </nav>

      <div className="max-w-4xl mx-auto px-6 py-12">
        <h1 className="text-4xl font-black mb-8">My Account</h1>

        {/* Profile Card */}
        <div className="bg-white sketch-border cartoon-shadow p-6 mb-6">
          <h2 className="text-xl font-bold mb-4">Profile</h2>
          <div className="grid sm:grid-cols-2 gap-4">
            <div>
              <div className="text-sm font-bold text-[#2D3436] opacity-60">Name</div>
              <div className="text-lg font-bold">{freshProfile?.full_name || 'Not set'}</div>
            </div>
            <div>
              <div className="text-sm font-bold text-[#2D3436] opacity-60">Email</div>
              <div className="text-lg font-bold">{user.email}</div>
            </div>
          </div>
        </div>

        {/* Credits Card */}
        <div className="bg-[#29AB87] text-white sketch-border cartoon-shadow p-6 mb-6">
          <h2 className="text-xl font-bold mb-4">Credits</h2>
          <div className="grid sm:grid-cols-3 gap-6">
            <div>
              <div className="text-sm opacity-80">Available</div>
              <div className="text-4xl font-black">{loadingData ? '...' : (freshProfile?.credits_remaining ?? (freshProfile?.credits_total ?? 0) - (freshProfile?.credits_used ?? 0) || 0)}</div>
            </div>
            <div>
              <div className="text-sm opacity-80">Used</div>
              <div className="text-4xl font-black">{loadingData ? '...' : (freshProfile?.credits_used || 0)}</div>
            </div>
            <div>
              <div className="text-sm opacity-80">Total Purchased</div>
              <div className="text-4xl font-black">{loadingData ? '...' : (freshProfile?.credits_total || 0)}</div>
            </div>
          </div>
          <a
            href="#/pricing"
            className="inline-block mt-6 bg-white text-[#29AB87] px-6 py-3 rounded-full font-bold sketch-border cartoon-shadow-hover transition-all"
          >
            Buy More Credits
          </a>
        </div>

        {/* Analytics Card */}
        {!loadingData && analytics && (
          <div className="bg-white sketch-border cartoon-shadow p-6 mb-6">
            <h2 className="text-xl font-bold mb-4">Activity Stats</h2>
            <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
              <div className="text-center p-4 bg-[#FAFAF8] sketch-border">
                <div className="text-3xl font-black text-[#29AB87]">
                  {analytics.total_files_organized}
                </div>
                <div className="text-sm font-bold opacity-60">Files Organized</div>
              </div>
              <div className="text-center p-4 bg-[#FAFAF8] sketch-border">
                <div className="text-3xl font-black text-[#FF6B6B]">
                  {analytics.total_folders_created}
                </div>
                <div className="text-sm font-bold opacity-60">Folders Created</div>
              </div>
              <div className="text-center p-4 bg-[#FAFAF8] sketch-border">
                <div className="text-3xl font-black text-[#FFD93D]">
                  {analytics.total_sessions}
                </div>
                <div className="text-sm font-bold opacity-60">Sessions</div>
              </div>
              <div className="text-center p-4 bg-[#FAFAF8] sketch-border">
                <div className="text-3xl font-black text-[#2D3436]">
                  {analytics.files_this_month}
                </div>
                <div className="text-sm font-bold opacity-60">This Month</div>
              </div>
            </div>
            {analytics.last_organization_at && (
              <div className="mt-4 text-sm text-[#2D3436] opacity-60">
                Last activity: {new Date(analytics.last_organization_at).toLocaleDateString()}
              </div>
            )}
          </div>
        )}

        {/* Purchase History */}
        <div className="bg-white sketch-border cartoon-shadow p-6">
          <h2 className="text-xl font-bold mb-4">Purchase History</h2>
          {analytics?.total_purchases === 0 ? (
            <div className="text-center py-8 text-[#2D3436] opacity-60">
              <div className="text-lg font-bold mb-2">No purchases yet</div>
              <a href="#pricing" className="text-[#29AB87] font-bold hover:underline">
                Get started with a credit pack
              </a>
            </div>
          ) : (
            <div className="text-sm text-[#2D3436] opacity-60">
              Total spent: {((analytics?.total_spent_cents || 0) / 100).toFixed(2)}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AccountPage;
