import React, { useState, useRef, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';

interface UserMenuProps {
  onBuyCredits?: () => void;
}

const UserMenu: React.FC<UserMenuProps> = ({ onBuyCredits }) => {
  const { user, profile, signOut } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  if (!user) return null;

  const initials = profile?.full_name
    ? profile.full_name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
    : user.email?.slice(0, 2).toUpperCase() || 'U';

  return (
    <div className="relative" ref={menuRef}>
      {/* User avatar button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 sketch-border bg-white px-3 py-2 cartoon-shadow-hover transition-all"
      >
        <div className="w-8 h-8 bg-[#29AB87] rounded-full flex items-center justify-center text-white font-bold text-sm">
          {initials}
        </div>
        <div className="hidden sm:block text-left">
          <div className="text-sm font-bold text-[#2D3436] truncate max-w-[120px]">
            {profile?.full_name || user.email?.split('@')[0]}
          </div>
          <div className="text-xs text-[#29AB87] font-bold">
            {profile?.credits_remaining || 0} credits
          </div>
        </div>
        <svg
          className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {/* Dropdown menu */}
      {isOpen && (
        <div className="absolute right-0 mt-2 w-64 bg-white sketch-border cartoon-shadow z-50">
          {/* User info */}
          <div className="p-4 border-b-4 border-[#2D3436]">
            <div className="font-bold text-[#2D3436]">{profile?.full_name || 'User'}</div>
            <div className="text-sm text-[#2D3436] opacity-60 truncate">{user.email}</div>
          </div>

          {/* Credits */}
          <div className="p-4 bg-[#FAFAF8] border-b-4 border-[#2D3436]">
            <div className="text-xs font-bold uppercase tracking-wider text-[#2D3436] opacity-60 mb-1">
              Available Credits
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-black text-[#29AB87]">
                {profile?.credits_remaining || 0}
              </span>
              <span className="text-sm text-[#2D3436] opacity-60">files</span>
            </div>
            {(profile?.credits_remaining || 0) < 10 && (
              <div className="mt-2 text-xs text-[#FF6B6B] font-bold">
                Running low! Buy more credits below.
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="p-2">
            <button
              onClick={() => {
                setIsOpen(false);
                onBuyCredits?.();
              }}
              className="w-full text-left px-3 py-2 font-bold text-[#29AB87] hover:bg-[#29AB87] hover:text-white transition-all rounded"
            >
              Buy More Credits
            </button>
            <a
              href="#/account"
              onClick={() => setIsOpen(false)}
              className="block w-full text-left px-3 py-2 font-bold text-[#2D3436] hover:bg-[#FAFAF8] transition-all rounded"
            >
              My Account
            </a>
            <button
              onClick={() => {
                signOut();
                setIsOpen(false);
              }}
              className="w-full text-left px-3 py-2 font-bold text-[#FF6B6B] hover:bg-[#FF6B6B] hover:text-white transition-all rounded"
            >
              Sign Out
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserMenu;
