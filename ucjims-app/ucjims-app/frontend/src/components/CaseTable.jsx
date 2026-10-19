import React, { useEffect, useState } from 'react';
import { apiFetch, getUser } from '../api.js';

const CAN_REGISTER = ['Investigator', 'Admin'];

const EMPTY_FORM = {
  case_number: '',
  case_type: '',
  incident_date: '',
  incident_location: '',
  description: '',
  priority: 'MEDIUM',
  fir_number: '',
  filed_by_user_id: '',
  complainant_id: '',
  station_name: '',
  fir_details: '',
};

export default function CaseTable() {
  const [cases, setCases] = useState([]);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState('');
  const [detail, setDetail] = useState(null);
  const [detailError, setDetailError] = useState('');
  const [selectedId, setSelectedId] = useState(null);

  const user = getUser();
  const canRegister = CAN_REGISTER.includes(user?.roleName);

  function loadCases() {
    apiFetch('/cases')
      .then(setCases)
      .catch((err) => setError(err.message));
  }

  useEffect(loadCases, []);

  function handleChange(e) {
    setForm({ ...form, [e.target.name]: e.target.value });
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setSubmitting(true);
    setFormError('');
    try {
      await apiFetch('/cases', { method: 'POST', body: JSON.stringify(form) });
      setForm(EMPTY_FORM);
      setShowForm(false);
      loadCases();
    } catch (err) {
      setFormError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  async function handleRowClick(id) {
    if (selectedId === id) {
      setSelectedId(null);
      setDetail(null);
      return;
    }
    setSelectedId(id);
    setDetail(null);
    setDetailError('');
    try {
      const rows = await apiFetch(`/cases/${id}`);
      setDetail(rows);
    } catch (err) {
      setDetailError(err.message);
    }
  }

  return (
    <section className="panel">
      <div className="panel-header">
        <h2>Cases</h2>
        {canRegister && (
          <button type="button" className="secondary" onClick={() => setShowForm((s) => !s)}>
            {showForm ? 'Cancel' : '+ Register case'}
          </button>
        )}
      </div>

      {showForm && (
        <form className="inline-form" onSubmit={handleSubmit}>
          <div className="form-grid">
            <label>
              Case number
              <input name="case_number" value={form.case_number} onChange={handleChange} required />
            </label>
            <label>
              Case type
              <input name="case_type" value={form.case_type} onChange={handleChange} required />
            </label>
            <label>
              Incident date
              <input type="date" name="incident_date" value={form.incident_date} onChange={handleChange} />
            </label>
            <label>
              Incident location
              <input name="incident_location" value={form.incident_location} onChange={handleChange} />
            </label>
            <label>
              Priority
              <select name="priority" value={form.priority} onChange={handleChange}>
                <option value="LOW">LOW</option>
                <option value="MEDIUM">MEDIUM</option>
                <option value="HIGH">HIGH</option>
              </select>
            </label>
            <label className="span-2">
              Description
              <input name="description" value={form.description} onChange={handleChange} />
            </label>
            <label>
              FIR number
              <input name="fir_number" value={form.fir_number} onChange={handleChange} required />
            </label>
            <label>
              Filed by (user ID)
              <input name="filed_by_user_id" value={form.filed_by_user_id} onChange={handleChange} />
            </label>
            <label>
              Complainant (person ID)
              <input name="complainant_id" value={form.complainant_id} onChange={handleChange} />
            </label>
            <label>
              Station name
              <input name="station_name" value={form.station_name} onChange={handleChange} />
            </label>
            <label className="span-2">
              FIR details
              <input name="fir_details" value={form.fir_details} onChange={handleChange} />
            </label>
          </div>
          {formError && <p className="error">{formError}</p>}
          <button type="submit" disabled={submitting}>
            {submitting ? 'Registering…' : 'Register case + FIR'}
          </button>
        </form>
      )}

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
            <React.Fragment key={c.CASE_ID}>
              <tr className="clickable" onClick={() => handleRowClick(c.CASE_ID)}>
                <td>{c.CASE_NUMBER}</td>
                <td>{c.CASE_TYPE}</td>
                <td>
                  <span className={`badge status-${c.CASE_STATUS}`}>{c.CASE_STATUS}</span>
                </td>
                <td>{c.PRIORITY}</td>
                <td>{c.REGISTRATION_DATE?.slice(0, 10)}</td>
              </tr>
              {selectedId === c.CASE_ID && (
                <tr className="detail-row">
                  <td colSpan={5}>
                    {detailError && <p className="error">{detailError}</p>}
                    {!detail && !detailError && <p className="empty">Loading case detail…</p>}
                    {detail && (
                      <div className="detail-cards">
                        {detail.map((row, idx) => (
                          <dl key={idx} className="detail-card">
                            {Object.entries(row).map(([k, v]) => (
                              <React.Fragment key={k}>
                                <dt>{k}</dt>
                                <dd>{v === null || v === undefined || v === '' ? '—' : String(v)}</dd>
                              </React.Fragment>
                            ))}
                          </dl>
                        ))}
                      </div>
                    )}
                  </td>
                </tr>
              )}
            </React.Fragment>
          ))}
        </tbody>
      </table>
      {cases.length === 0 && !error && <p className="empty">No cases to show.</p>}
    </section>
  );
}
