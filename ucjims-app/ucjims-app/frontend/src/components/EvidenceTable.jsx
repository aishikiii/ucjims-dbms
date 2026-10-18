import React, { useEffect, useState } from 'react';
import { apiFetch } from '../api.js';

export default function EvidenceTable() {
  const [items, setItems] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    apiFetch('/evidence')
      .then(setItems)
      .catch((err) => setError(err.message));
  }, []);

  return (
    <section className="panel">
      <h2>Evidence</h2>
      {error && <p className="error">{error}</p>}
      <table>
        <thead>
          <tr>
            <th>Evidence ID</th>
            <th>Case</th>
            <th>Type</th>
            <th>Description</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {items.map((e) => (
            <tr key={e.EVIDENCE_ID}>
              <td>{e.EVIDENCE_ID}</td>
              <td>{e.CASE_ID}</td>
              <td>{e.EVIDENCE_TYPE}</td>
              <td>{e.DESCRIPTION}</td>
              <td>
                <span className={`badge status-${e.CURRENT_STATUS}`}>{e.CURRENT_STATUS}</span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      {items.length === 0 && !error && <p className="empty">No evidence to show.</p>}
    </section>
  );
}
