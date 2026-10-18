import React, { useEffect, useState } from 'react';
import { apiFetch } from '../api.js';

export default function CaseTable() {
  const [cases, setCases] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    apiFetch('/cases')
      .then(setCases)
      .catch((err) => setError(err.message));
  }, []);

  return (
    <section className="panel">
      <h2>Cases</h2>
      {error && <p className="error">{error}</p>}
      <table>
        <thead>
          <tr>
            <th>Case #</th>
            <th>Type</th>
            <th>Status</th>
            <th>Priority</th>
            <th>Registered</th>
          </tr>
        </thead>
        <tbody>
          {cases.map((c) => (
            <tr key={c.CASE_ID}>
              <td>{c.CASE_NUMBER}</td>
              <td>{c.CASE_TYPE}</td>
              <td>
                <span className={`badge status-${c.CASE_STATUS}`}>{c.CASE_STATUS}</span>
              </td>
              <td>{c.PRIORITY}</td>
              <td>{c.REGISTRATION_DATE?.slice(0, 10)}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {cases.length === 0 && !error && <p className="empty">No cases to show.</p>}
    </section>
  );
}
