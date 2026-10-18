import React, { useEffect, useState } from 'react';
import { apiFetch } from '../api.js';

export default function CourtTable() {
  const [hearings, setHearings] = useState([]);
  const [judgments, setJudgments] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([apiFetch('/court/hearings'), apiFetch('/court/judgments').catch(() => [])])
      .then(([h, j]) => {
        setHearings(h);
        setJudgments(j);
      })
      .catch((err) => setError(err.message));
  }, []);

  return (
    <>
      <section className="panel">
        <h2>Hearings</h2>
        {error && <p className="error">{error}</p>}
        <table>
          <thead>
            <tr>
              <th>Hearing ID</th>
              <th>Case</th>
              <th>Date</th>
              <th>Type</th>
              <th>Courtroom</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {hearings.map((h) => (
              <tr key={h.HEARING_ID}>
                <td>{h.HEARING_ID}</td>
                <td>{h.CASE_ID}</td>
                <td>{h.HEARING_DATE?.slice(0, 10)}</td>
                <td>{h.HEARING_TYPE}</td>
                <td>{h.COURTROOM}</td>
                <td>{h.HEARING_STATUS}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {hearings.length === 0 && !error && <p className="empty">No hearings to show.</p>}
      </section>

      {judgments.length > 0 && (
        <section className="panel">
          <h2>Judgments</h2>
          <table>
            <thead>
              <tr>
                <th>Judgment ID</th>
                <th>Case</th>
                <th>Date</th>
                <th>Verdict</th>
              </tr>
            </thead>
            <tbody>
              {judgments.map((j) => (
                <tr key={j.JUDGMENT_ID}>
                  <td>{j.JUDGMENT_ID}</td>
                  <td>{j.CASE_ID}</td>
                  <td>{j.JUDGMENT_DATE?.slice(0, 10)}</td>
                  <td>{j.VERDICT}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}
    </>
  );
}
