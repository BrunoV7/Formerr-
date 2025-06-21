'use client';

import { useState, useRef, useEffect, ReactNode } from 'react';

interface PopoverProps {
  children: ReactNode;
  content: ReactNode;
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  align?: 'start' | 'center' | 'end';
  side?: 'top' | 'bottom' | 'left' | 'right';
  className?: string;
}

export function Popover({
  children,
  content,
  isOpen,
  onOpenChange,
  align = 'end',
  side = 'bottom',
  className = ''
}: PopoverProps) {
  const popoverRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        popoverRef.current &&
        triggerRef.current &&
        !popoverRef.current.contains(event.target as Node) &&
        !triggerRef.current.contains(event.target as Node)
      ) {
        onOpenChange(false);
      }
    };

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
      document.addEventListener('keydown', handleEscapeKey);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handleEscapeKey);
    };
  }, [isOpen, onOpenChange]);

  const handleEscapeKey = (event: KeyboardEvent) => {
    if (event.key === 'Escape') {
      onOpenChange(false);
    }
  };

  const getPositionClasses = () => {
    const baseClasses = 'absolute z-[9999]';
    
    let positionClasses = '';
    
    switch (side) {
      case 'top':
        positionClasses = 'bottom-full mb-2';
        break;
      case 'bottom':
        positionClasses = 'top-full mt-2';
        break;
      case 'left':
        positionClasses = 'right-full mr-2 top-0';
        break;
      case 'right':
        positionClasses = 'left-full ml-2 top-0';
        break;
    }

    switch (align) {
      case 'start':
        if (side === 'top' || side === 'bottom') {
          positionClasses += ' left-0';
        } else {
          positionClasses += ' top-0';
        }
        break;
      case 'center':
        if (side === 'top' || side === 'bottom') {
          positionClasses += ' left-1/2 transform -translate-x-1/2';
        } else {
          positionClasses += ' top-1/2 transform -translate-y-1/2';
        }
        break;
      case 'end':
        if (side === 'top' || side === 'bottom') {
          positionClasses += ' right-0';
        } else {
          positionClasses += ' bottom-0';
        }
        break;
    }

    return `${baseClasses} ${positionClasses}`;
  };

  return (
    <div className="relative inline-block">
      <div ref={triggerRef}>
        {children}
      </div>
      
      {isOpen && (
        <div
          ref={popoverRef}
          className={`${getPositionClasses()} ${className}`}
        >
          <div className="bg-white rounded-lg shadow-lg border border-gray-200 py-1 min-w-[160px]">
            {content}
          </div>
        </div>
      )}
    </div>
  );
}

interface PopoverItemProps {
  children: ReactNode;
  onClick?: () => void;
  className?: string;
  disabled?: boolean;
  icon?: ReactNode;
}

export function PopoverItem({
  children,
  onClick,
  className = '',
  disabled = false,
  icon
}: PopoverItemProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`
        w-full px-4 py-2 text-left text-sm hover:bg-gray-50 transition-colors
        flex items-center gap-3
        ${disabled ? 'text-gray-400 cursor-not-allowed' : 'text-gray-700'}
        ${className}
      `}
    >
      {icon && (
        <span className="flex-shrink-0">
          {icon}
        </span>
      )}
      {children}
    </button>
  );
}

interface PopoverSeparatorProps {
  className?: string;
}

export function PopoverSeparator({ className = '' }: PopoverSeparatorProps) {
  return <div className={`border-t border-gray-200 my-1 ${className}`} />;
}
