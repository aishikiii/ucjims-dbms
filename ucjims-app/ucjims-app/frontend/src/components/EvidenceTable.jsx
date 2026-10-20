import React, { useEffect, useState } from 'react';
import { apiFetch, getUser } from '../api.js';

const CAN_TRANSFER = ['Forensic Officer', 'Admin'];

const EMPTY_FORM = {
  from_user_id: '',
  to_user_id: '',
  transfer_location: '',
  storage_location: '',
  purpose: '',
  condition: '',
  remarks: '',
};

export default function EvidenceTable() {
  const [items, setItems] = useState([]);
  const [error, setError] = useState('');
  const [activeId, setActiveId] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState('');
  const [formSuccess, setFormSuccess] = useState('');

  const user = getUser();
  const canTransfer = CAN_TRANSFER.includes(user?.roleName);

  function loadEvidence() {
    apiFetch('/evidence')
      .then(setItems)
      .catch((err) => setError(err.message));
  }

  useEffect(loadEvidence, []);

  function openTransferForm(id) {
    setActiveId(activeId === id ? null : id);
    setForm(EMPTY_FORM);
    setFormError('');
    setFormSuccess('');
  }

  function handleChange(e) {
    setForm({ ...form, [e.target.name]: e.target.value });
  }

  async function handleSubmit(e, evidenceId) {
    e.preventDefault();
    setSubmitting(true);
    setFormError('');
    try {
      await apiFetch(`/evidence/${evidenceId}/transfer`, { method: 'POST', body: JSON.stringify(form) });
      setFormSuccess('Transfer recorded.');
      setForm(EMPTY_FORM);
      loadEvidence();
    } catch (err) {
      setFormError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

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
            {canTransfer && <th />}
          </tr>
        </thead>
        <tbody>
          {items.map((e) => (
            <React.Fragment key={e.EVIDENCE_ID}>
              <tr>
                <td>{e.EVIDENCE_ID}</td>
                <td>{e.CASE_ID}</td>
                <td>{e.EVIDENCE_TYPE}</td>
                <td>{e.DESCRIPTION}</td>
                <td>
                  <span className={`badge status-${e.CURRENT_STATUS}`}>{e.CURRENT_STATUS}</span>
                </td>
                {canTransfer && (
                  <td>
                    <button type="button" className="secondary" onClick={() => openTransferForm(e.EVIDENCE_ID)}>
                      {activeId === e.EVIDENCE_ID ? 'Cancel' : 'Transfer'}
                    </button>
                  </td>
                )}
              </tr>
              {canTransfer && activeId === e.EVIDENCE_ID && (
                <tr>
                  <td colSpan={6}>
                    <form className="inline-form" onSubmit={(ev) => handleSubmit(ev, e.EVIDENCE_ID)}>
                      <div className="form-grid">
                        <label>
                          From (user ID)
                          <input name="from_user_id" value={form.from_user_id} onChange={handleChange} />
                        </label>
                        <label>
                          To (user ID)
                          <input name="to_user_id" value={form.to_user_id} onChange={handleChange} required />
                        </label>
                        <label>
                          Transfer location
                          <input name="transfer_location" value={form.transfer_location} onChange={handleChange} required />
                        </label>
                        <label>
                          Storage location
                          <input name="storage_location" placeholder="e.g. Evidence Locker 4" value={form.storage_location} onChange={handleChange} />
                        </label>
                        <label>
                          Purpose
                          <input name="purpose" value={form.purpose} onChange={handleChange} />
                        </label>
                        <label>
                          Condition
                          <input name="condition" value={form.condition} onChange={handleChange} />
                        </label>
                        <label className="span-2">
                          Remarks
                          <input name="remarks" value={form.remarks} onChange={handleChange} />
                        </label>
                      </div>
                      {formError && <p className="error">{formError}</p>}
                      {formSuccess && <p className="success">{formSuccess}</p>}
                      <button type="submit" disabled={submitting}>
                        {submitting ? 'Recording...' : 'Record transfer'}
                      </button>
                    </form>
                  </td>
                </tr>
              )}
            </React.Fragment>
          ))}
        </tbody>
      </table>
      {items.length === 0 && !error && <div className="empty-state"><div style={{fontSize:'2rem'}}>🔬</div><p>No evidence records found.</p></div>}
    </section>
  );
}
