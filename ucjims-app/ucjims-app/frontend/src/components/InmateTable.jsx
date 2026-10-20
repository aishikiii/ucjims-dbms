import React, { useEffect, useState } from 'react';
import { apiFetch, getUser } from '../api.js';

const CAN_MANAGE = ['Prison Officer', 'Admin'];
const EMPTY_ADMIT_FORM = { person_id: '', prison_id: '', expected_release_date: '' };
const EMPTY_TRANSFER_FORM = { to_prison_id: '', reason: '' };

export default function InmateTable() {
  const [inmates, setInmates] = useState([]);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(EMPTY_ADMIT_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState('');
  const [releasingId, setReleasingId] = useState(null);

  // Transfer state
  const [transferringId, setTransferringId] = useState(null);
  const [transferForm, setTransferForm] = useState(EMPTY_TRANSFER_FORM);
  const [transferSubmitting, setTransferSubmitting] = useState(false);
  const [transferError, setTransferError] = useState('');

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
      setForm(EMPTY_ADMIT_FORM);
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

  async function handleTransferSubmit(e, id) {
    e.preventDefault();
    setTransferSubmitting(true);
    setTransferError('');
    try {
      await apiFetch(`/court/inmates/${id}/transfer`, {
        method: 'POST',
        body: JSON.stringify(transferForm),
      });
      setTransferringId(null);
      setTransferForm(EMPTY_TRANSFER_FORM);
      loadInmates();
    } catch (err) {
      setTransferError(err.message);
    } finally {
      setTransferSubmitting(false);
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
            {submitting ? 'Admitting...' : 'Admit inmate'}
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
            {canManage && <th>Actions</th>}
          </tr>
        </thead>
        <tbody>
          {inmates.map((i) => (
            <React.Fragment key={i.INMATE_ID}>
              <tr>
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
                    {i.STATUS === 'INCARCERATED' && (
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        <button
                          type="button"
                          className="secondary"
                          onClick={() => {
                            setTransferringId(transferringId === i.INMATE_ID ? null : i.INMATE_ID);
                            setTransferError('');
                          }}
                        >
                          {transferringId === i.INMATE_ID ? 'Cancel Transfer' : 'Transfer'}
                        </button>
                        <button
                          type="button"
                          className="secondary"
                          disabled={releasingId === i.INMATE_ID}
                          onClick={() => handleRelease(i.INMATE_ID)}
                        >
                          {releasingId === i.INMATE_ID ? 'Releasing...' : 'Release'}
                        </button>
                      </div>
                    )}
                  </td>
                )}
              </tr>
              {transferringId === i.INMATE_ID && (
                <tr>
                  <td colSpan={canManage ? 7 : 6} style={{ background: '#f8fafc', padding: '1rem' }}>
                    <form onSubmit={(e) => handleTransferSubmit(e, i.INMATE_ID)}>
                      <h4>Transfer Inmate #{i.INMATE_ID} to another facility</h4>
                      <div className="form-grid" style={{ marginTop: '0.5rem' }}>
                        <label>
                          Destination Prison ID
                          <input
                            type="number"
                            required
                            value={transferForm.to_prison_id}
                            onChange={(e) =>
                              setTransferForm({ ...transferForm, to_prison_id: e.target.value })
                            }
                          />
                        </label>
                        <label>
                          Transfer Reason
                          <input
                            required
                            placeholder="e.g. Security reclassification, medical"
                            value={transferForm.reason}
                            onChange={(e) =>
                              setTransferForm({ ...transferForm, reason: e.target.value })
                            }
                          />
                        </label>
                      </div>
                      {transferError && <p className="error">{transferError}</p>}
                      <div style={{ marginTop: '0.5rem' }}>
                        <button type="submit" disabled={transferSubmitting}>
                          {transferSubmitting ? 'Recording Transfer...' : 'Confirm Transfer'}
                        </button>
                      </div>
                    </form>
                  </td>
                </tr>
              )}
            </React.Fragment>
          ))}
        </tbody>
      </table>
      {inmates.length === 0 && !error && <div className="empty-state"><div style={{fontSize:'2rem'}}>🏛️</div><p>No inmate records found.</p></div>}
    </section>
  );
}
