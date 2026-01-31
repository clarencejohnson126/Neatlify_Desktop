import React, { useState } from 'react';

interface FlipCardProps {
  frontContent: React.ReactNode;
  backContent: React.ReactNode;
  className?: string;
  frontClassName?: string;
  backClassName?: string;
}

export const FlipCard: React.FC<FlipCardProps> = ({
  frontContent,
  backContent,
  className = '',
  frontClassName = '',
  backClassName = '',
}) => {
  const [isFlipped, setIsFlipped] = useState(false);

  return (
    <div
      className={`flip-card ${isFlipped ? 'flipped' : ''} ${className}`}
      onClick={() => setIsFlipped(!isFlipped)}
    >
      <div className="flip-card-inner">
        <div className={`flip-card-front ${frontClassName}`}>
          {frontContent}
          <div className="absolute bottom-3 right-3 text-xs opacity-50 font-bold flex items-center gap-1">
            <span>Click to flip</span>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M17 1l4 4-4 4"/>
              <path d="M3 11V9a4 4 0 0 1 4-4h14"/>
              <path d="M7 23l-4-4 4-4"/>
              <path d="M21 13v2a4 4 0 0 1-4 4H3"/>
            </svg>
          </div>
        </div>
        <div className={`flip-card-back ${backClassName}`}>
          {backContent}
          <div className="absolute bottom-3 right-3 text-xs opacity-50 font-bold flex items-center gap-1">
            <span>Click to flip back</span>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M17 1l4 4-4 4"/>
              <path d="M3 11V9a4 4 0 0 1 4-4h14"/>
            </svg>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FlipCard;
