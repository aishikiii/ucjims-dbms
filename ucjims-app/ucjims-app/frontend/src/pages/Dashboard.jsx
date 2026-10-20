import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getUser, clearSession } from '../api.js';
import CaseTable from '../components/CaseTable.jsx';
import EvidenceTable from '../components/EvidenceTable.jsx';
import CourtTable from '../components/CourtTable.jsx';
import InmateTable from '../components/InmateTable.jsx';

const ROLE_PANELS = {
  Investigator: ['cases', 'evidence', 'court'],
  'Cyber Crime Analyst': ['cases', 'evidence'],
  'Forensic Officer': ['evidence'],
  Judge: ['court'],
  Prosecutor: ['court'],
  'Prison Officer': ['inmates'],
  Admin: ['cases', 'evidence', 'court', 'inmates'],
};

const PANEL_META = {
  cases:    { label: 'Cases',    icon: '📁', desc: 'Manage criminal cases and FIRs' },
  evidence: { label: 'Evidence', icon: '🔬', desc: 'Evidence logs and custody chain' },
  court:    { label: 'Court',    icon: '⚖️', desc: 'Hearings and judgments' },
  inmates:  { label: 'Inmates',  icon: '🏛️', desc: 'Inmate records and transfers' },
};

const ROLE_COLORS = {
  Admin: 'role-admin',
  Investigator: 'role-investigator',
  'Cyber Crime Analyst': 'role-cyber',
  'Forensic Officer': 'role-forensic',
  Judge: 'role-judge',
  Prosecutor: 'role-prosecutor',
  'Prison Officer': 'role-prison',
};

export default function Dashboard() {
  const user = getUser();
  const navigate = useNavigate();
  const panels = ROLE_PANELS[user?.roleName] || [];
  const [activePanel, setActivePanel] = useState(panels[0] || null);

  function handleLogout() {
    clearSession();
    navigate('/login');
  }

  return (
    <div className="dashboard">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <span className="sidebar-logo">⚖️</span>
          <div>
            <div className="sidebar-title">UCJIMS</div>
            <div className="sidebar-subtitle">Justice System</div>
          </div>
        </div>

        <div className="sidebar-user">
          <div className="sidebar-avatar">{user?.fullName?.[0] || user?.username?.[0] || '?'}</div>
          <div className="sidebar-user-info">
            <div className="sidebar-username">{user?.fullName || user?.username}</div>
            <span className={`role-badge ${ROLE_COLORS[user?.roleName] || ''}`}>{user?.roleName}</span>
          </div>
        </div>

        <nav className="sidebar-nav">
          <div className="sidebar-nav-label">Navigation</div>
          {panels.map((panel) => (
            <button
              key={panel}
              type="button"
              className={`sidebar-nav-item ${activePanel === panel ? 'active' : ''}`}
              onClick={() => setActivePanel(panel)}
            >
              <span className="nav-icon">{PANEL_META[panel].icon}</span>
              <span>{PANEL_META[panel].label}</span>
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          <button type="button" className="sidebar-logout" onClick={handleLogout}>
            🚪 Sign Out
          </button>
        </div>
      </aside>

      {/* Main area */}
      <div className="main-area">
        <header className="topbar">
          <div className="topbar-left">
            {activePanel && (
              <>
                <span className="topbar-icon">{PANEL_META[activePanel]?.icon}</span>
                <div>
                  <div className="topbar-title">{PANEL_META[activePanel]?.label}</div>
                  <div className="topbar-desc">{PANEL_META[activePanel]?.desc}</div>
                </div>
              </>
            )}
          </div>
          <div className="topbar-right">
            <span className="topbar-date">{new Date().toLocaleDateString('en-IN', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</span>
          </div>
        </header>

        <main className="main-content">
          {!activePanel && (
            <div className="welcome-card">
              <div className="welcome-icon">⚖️</div>
              <div>
                <h2>Welcome, {user?.fullName || user?.username}!</h2>
                <p>You are signed in as <strong>{user?.roleName}</strong>. Select a module from the sidebar to get started.</p>
              </div>
            </div>
          )}

          {panels.length === 0 && (
            <div className="empty-state">
              <div style={{ fontSize: '3rem' }}>🔐</div>
              <p>No dashboard panels are configured for your role yet.</p>
            </div>
          )}

          {activePanel === 'cases' && panels.includes('cases') && <CaseTable />}
          {activePanel === 'evidence' && panels.includes('evidence') && <EvidenceTable />}
          {activePanel === 'court' && panels.includes('court') && <CourtTable />}
          {activePanel === 'inmates' && panels.includes('inmates') && <InmateTable />}
        </main>
      </div>
    </div>
  );
}
