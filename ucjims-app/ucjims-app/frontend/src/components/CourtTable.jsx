import React, { useEffect, useState } from 'react';
import { apiFetch, getUser } from '../api.js';

const CAN_MANAGE = ['Judge', 'Admin'];

const EMPTY_HEARING = { case_id: '', court_id: '', judge_id: '', hearing_date: '', hearing_type: '', courtroom: '' };
const EMPTY_JUDGMENT = { case_id: '', verdict: '', judgment_summary: '' };

export default function CourtTable() {
  const [hearings, setHearings] = useState([]);
  const [judgments, setJudgments] = useState([]);
  const [error, setError] = useState('');

  const [showHearingForm, setShowHearingForm] = useState(false);
  const [hearingForm, setHearingForm] = useState(EMPTY_HEARING);
  const [hearingError, setHearingError] = useState('');
  const [hearingSubmitting, setHearingSubmitting] = useState(false);

  const [showJudgmentForm, setShowJudgmentForm] = useState(false);
  const [judgmentForm, setJudgmentForm] = useState(EMPTY_JUDGMENT);
  const [judgmentError, setJudgmentError] = useState('');
  const [judgmentSubmitting, setJudgmentSubmitting] = useState(false);

  const user = getUser();
  const canManage = CAN_MANAGE.includes(user?.roleName);

  function loadData() {
    Promise.all([apiFetch('/court/hearings'), apiFetch('/court/judgments').catch(() => [])])
      .then(([h, j]) => {
        setHearings(h);
        setJudgments(j);
      })
      .catch((err) => setError(err.message));
  }

  useEffect(loadData, []);

  async function submitHearing(e) {
    e.preventDefault();
    setHearingSubmitting(true);
    setHearingError('');
    try {
      await apiFetch('/court/hearings', { method: 'POST', body: JSON.stringify(hearingForm) });
      setHearingForm(EMPTY_HEARING);
      setShowHearingForm(false);
      loadData();
    } catch (err) {
      setHearingError(err.message);
    } finally {
      setHearingSubmitting(false);
    }
  }

  async function submitJudgment(e) {
    e.preventDefault();
    setJudgmentSubmitting(true);
    setJudgmentError('');
    try {
      await apiFetch('/court/judgments', { method: 'POST', body: JSON.stringify(judgmentForm) });
      setJudgmentForm(EMPTY_JUDGMENT);
      setShowJudgmentForm(false);
      loadData();
    } catch (err) {
      setJudgmentError(err.message);
    } finally {
      setJudgmentSubmitting(false);
    }
  }

  return (
    <>
      <section className="panel">
        <div className="panel-header">
          <h2>Hearings</h2>
          {canManage && (
            <button type="button" className="secondary" onClick={() => setShowHearingForm((s) => !s)}>
              {showHearingForm ? 'Cancel' : '+ Schedule hearing'}
            </button>
          )}
        </div>

        {showHearingForm && (
          <form className="inline-form" onSubmit={submitHearing}>
            <div className="form-grid">
              <label>
                Case ID
                <input
                  value={hearingForm.case_id}
                  onChange={(e) => setHearingForm({ ...hearingForm, case_id: e.target.value })}
                  required
                />
              </label>
              <label>
                Court ID
                <input
                  value={hearingForm.court_id}
                  onChange={(e) => setHearingForm({ ...hearingForm, court_id: e.target.value })}
                />
              </label>
              <label>
                Judge ID
                <input
                  value={hearingForm.judge_id}
                  onChange={(e) => setHearingForm({ ...hearingForm, judge_id: e.target.value })}
                />
              </label>
              <label>
                Hearing date
                <input
                  type="date"
                  value={hearingForm.hearing_date}
                  onChange={(e) => setHearingForm({ ...hearingForm, hearing_date: e.target.value })}
                  required
                />
              </label>
              <label>
                Hearing type
                <input
                  value={hearingForm.hearing_type}
                  onChange={(e) => setHearingForm({ ...hearingForm, hearing_type: e.target.value })}
                  required
                />
              </label>
              <label>
                Courtroom
                <input
                  value={hearingForm.courtroom}
                  onChange={(e) => setHearingForm({ ...hearingForm, courtroom: e.target.value })}
                />
              </label>
            </div>
            {hearingError && <p className="error">{hearingError}</p>}
            <button type="submit" disabled={hearingSubmitting}>
              {hearingSubmitting ? 'Scheduling…' : 'Schedule hearing'}
            </button>
          </form>
        )}

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

      <section className="panel">
        <div className="panel-header">
          <h2>Judgments</h2>
          {canManage && (
            <button type="button" className="secondary" onClick={() => setShowJudgmentForm((s) => !s)}>
              {showJudgmentForm ? 'Cancel' : '+ Record judgment'}
            </button>
          )}
        </div>

        {showJudgmentForm && (
          <form className="inline-form" onSubmit={submitJudgment}>
            <div className="form-grid">
              <label>
                Case ID
                <input
                  value={judgmentForm.case_id}
                  onChange={(e) => setJudgmentForm({ ...judgmentForm, case_id: e.target.value })}
                  required
                />
              </label>
              <label>
                Verdict
                <input
                  value={judgmentForm.verdict}
                  onChange={(e) => setJudgmentForm({ ...judgmentForm, verdict: e.target.value })}
                  required
                />
              </label>
              <label className="span-2">
                Summary
                <input
                  value={judgmentForm.judgment_summary}
                  onChange={(e) => setJudgmentForm({ ...judgmentForm, judgment_summary: e.target.value })}
                />
              </label>
            </div>
            {judgmentError && <p className="error">{judgmentError}</p>}
            <button type="submit" disabled={judgmentSubmitting}>
              {judgmentSubmitting ? 'Recording…' : 'Record judgment'}
            </button>
          </form>
        )}

        {judgments.length > 0 ? (
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
        ) : (
          <p className="empty">No judgments to show.</p>
        )}
      </section>
    </>
  );
}
