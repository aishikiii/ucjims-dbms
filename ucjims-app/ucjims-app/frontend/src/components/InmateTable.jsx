import React, { useEffect, useState } from 'react';
import { apiFetch } from '../api.js';

export default function InmateTable() {
  const [inmates, setInmates] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    apiFetch('/court/inmates')
      .then(setInmates)
      .catch((err) => setError(err.message));
  }, []);

  return (
    <section className="panel">
      <h2>Inmates</h2>
      {error && <p className="error">{error}</p>}
      <table>
        <thead>
          <tr>
            <th>Inmate ID</th>
            <th>Name</th>
            <th>Prison</th>
            <th>Admitted</th>
            <th>Expected Release</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {inmates.map((i) => (
            <tr key={i.INMATE_ID}>
              <td>{i.INMATE_ID}</td>
              <td>{i.INMATE_NAME}</td>
              <td>{i.PRISON_NAME}</td>
              <td>{i.ADMISSION_DATE?.slice(0, 10)}</td>
              <td>{i.EXPECTED_RELEASE_DATE?.slice(0, 10) || '—'}</td>
              <td>
                <span className={`badge status-${i.STATUS}`}>{i.STATUS}</span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      {inmates.length === 0 && !error && <p className="empty">No inmates to show.</p>}
    </section>
  );
}
