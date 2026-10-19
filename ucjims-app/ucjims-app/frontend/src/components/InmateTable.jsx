import React, { useEffect, useState } from 'react';
import { apiFetch, getUser } from '../api.js';

const CAN_MANAGE = ['Prison Officer', 'Admin'];
const EMPTY_FORM = { person_id: '', prison_id: '', expected_release_date: '' };

export default function InmateTable() {
  const [inmates, setInmates] = useState([]);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState('');
  const [releasingId, setReleasingId] = useState(null);

  const user = getUser();
  const canManage = CAN_MANAGE.includes(user?.roleName);

  function loadInmates() {
    apiFetch('/court/inmates')
      .then(setInmates)
      .catch((err) => setError(err.message));
  }

  useEffect(loadInmates, []);

  async function handleSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    setFormError('');
    try {
      await apiFetch('/court/inmates', { method: 'POST', body: JSON.stringify(form) });
      setForm(EMPTY_FORM);
      setShowForm(false);
      loadInmates();
    } catch (err) {
      setFormError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  async function handleRelease(id) {
    setReleasingId(id);
    try {
      await apiFetch(`/court/inmates/${id}/release`, { method: 'PATCH' });
      loadInmates();
    } catch (err) {
      setError(err.message);
    } finally {
      setReleasingId(null);
    }
  }

  return (
    <section className="panel">
      <div className="panel-header">
        <h2>Inmates</h2>
        {canManage && (
          <button type="button" className="secondary" onClick={() => setShowForm((s) => !s)}>
            {showForm ? 'Cancel' : '+ Admit inmate'}
          </button>
        )}
      </div>

      {showForm && (
        <form className="inline-form" onSubmit={handleSubmit}>
          <div className="form-grid">
            <label>
              Person ID
              <input
                value={form.person_id}
                onChange={(e) => setForm({ ...form, person_id: e.target.value })}
                required
              />
            </label>
            <label>
              Prison ID
              <input
                value={form.prison_id}
                onChange={(e) => setForm({ ...form, prison_id: e.target.value })}
                required
              />
            </label>
            <label>
              Expected release date
              <input
                type="date"
                value={form.expected_release_date}
                onChange={(e) => setForm({ ...form, expected_release_date: e.target.value })}
              />
            </label>
          </div>
          {formError && <p className="error">{formError}</p>}
          <button type="submit" disabled={submitting}>
            {submitting ? 'Admitting…' : 'Admit inmate'}
          </button>
        </form>
      )}

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
            {canManage && <th />}
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
              {canManage && (
                <td>
                  {i.STATUS !== 'RELEASED' && (
                    <button
                      type="button"
                      className="secondary"
                      disabled={releasingId === i.INMATE_ID}
                      onClick={() => handleRelease(i.INMATE_ID)}
                    >
                      {releasingId === i.INMATE_ID ? 'Releasing…' : 'Release'}
                    </button>
                  )}
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
      {inmates.length === 0 && !error && <p className="empty">No inmates to show.</p>}
    </section>
  );
}
