import React from 'react';
import { useNavigate } from 'react-router-dom';
import { getUser, clearSession } from '../api.js';
import CaseTable from '../components/CaseTable.jsx';
import EvidenceTable from '../components/EvidenceTable.jsx';
import CourtTable from '../components/CourtTable.jsx';
import InmateTable from '../components/InmateTable.jsx';

// Which panels each role sees. Admin sees everything; others see only
// what their role needs - mirrors the RBAC view design from the SQL layer.
const ROLE_PANELS = {
  Investigator: ['cases', 'evidence', 'court'],
  'Cyber Crime Analyst': ['cases', 'evidence'],
  'Forensic Officer': ['evidence'],
  Judge: ['court'],
  Prosecutor: ['court'],
  'Prison Officer': ['inmates'],
  Admin: ['cases', 'evidence', 'court', 'inmates'],
};

export default function Dashboard() {
  const user = getUser();
  const navigate = useNavigate();
  const panels = ROLE_PANELS[user?.roleName] || [];

  function handleLogout() {
    clearSession();
    navigate('/login');
  }

  return (
    <div className="dashboard">
      <header className="topbar">
        <div>
          <strong>UCJIMS</strong>
          <span className="role-badge">{user?.roleName}</span>
        </div>
        <div>
          <span>{user?.fullName}</span>
          <button onClick={handleLogout}>Log out</button>
        </div>
      </header>

      <main>
        {panels.length === 0 && <p>No dashboard panels are configured for your role yet.</p>}
        {panels.includes('cases') && <CaseTable />}
        {panels.includes('evidence') && <EvidenceTable />}
        {panels.includes('court') && <CourtTable />}
        {panels.includes('inmates') && <InmateTable />}
      </main>
    </div>
  );
}
