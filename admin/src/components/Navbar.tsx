import React from 'react';
import { clearAuthToken } from '../api';
import { Flag, LogOut, ArrowLeft } from 'lucide-react';

interface NavbarProps {
  user: any;
  selectedCourse: any;
  onBackToCourses: () => void;
  onLogout: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  user,
  selectedCourse,
  onBackToCourses,
  onLogout,
}) => {
  return (
    <header
      style={{
        height: '56px',
        backgroundColor: '#0f172a',
        borderBottom: '1px solid #1e293b',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 20px',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div
            style={{
              backgroundColor: '#10b981',
              width: '32px',
              height: '32px',
              borderRadius: '6px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Flag size={18} color="#ffffff" />
          </div>
          <span style={{ fontWeight: 'bold', fontSize: '16px', letterSpacing: '-0.3px' }}>
            TechGolf <span style={{ color: '#10b981' }}>GIS Admin</span>
          </span>
        </div>

        {selectedCourse && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <button
              onClick={onBackToCourses}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
                padding: '6px 12px',
                borderRadius: '6px',
                backgroundColor: '#1e293b',
                color: '#94a3b8',
                border: '1px solid #334155',
                cursor: 'pointer',
                fontSize: '12px',
              }}
            >
              <ArrowLeft size={14} /> Back to Courses
            </button>
            <span style={{ color: '#64748b' }}>/</span>
            <span style={{ fontWeight: 600, fontSize: '14px', color: '#f8fafc' }}>
              {selectedCourse.name}
            </span>
          </div>
        )}
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        {user ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <span style={{ fontSize: '13px', color: '#94a3b8' }}>
              {user.email} <span style={{ color: '#38bdf8', fontWeight: 'bold' }}>({user.role})</span>
            </span>
            <button
              onClick={() => {
                clearAuthToken();
                onLogout();
              }}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '6px 10px',
                backgroundColor: '#334155',
                color: '#f87171',
                border: 'none',
                borderRadius: '6px',
                cursor: 'pointer',
                fontSize: '12px',
              }}
            >
              <LogOut size={14} /> Logout
            </button>
          </div>
        ) : (
          <span style={{ fontSize: '13px', color: '#f59e0b' }}>Guest Mode (Read-only)</span>
        )}
      </div>
    </header>
  );
};
