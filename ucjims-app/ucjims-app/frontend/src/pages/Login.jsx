import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiFetch, setSession } from '../api.js';

export default function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const data = await apiFetch('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ username, password }),
      });
      setSession(data.token, data.user);
      navigate('/');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login-page">
      <div className="login-split">
        {/* Left branding panel */}
        <div className="login-brand">
          <div className="login-brand-icon">⚖️</div>
          <h1 className="login-brand-title">UCJIMS</h1>
          <p className="login-brand-sub">Unified Criminal Justice Information Management System</p>
          <ul className="login-brand-features">
            <li>🔒 Secure Role-Based Access</li>
            <li>📁 Case & Evidence Management</li>
            <li>⚖️ Court Hearings & Judgments</li>
            <li>🏛️ Inmate Records & Transfers</li>
          </ul>
          <p className="login-brand-footer">Empowering justice through technology</p>
        </div>

        {/* Right form panel */}
        <div className="login-form-panel">
          <form className="login-card" onSubmit={handleSubmit}>
            <div className="login-card-header">
              <span className="login-card-icon">🛡️</span>
              <h2>Secure Sign In</h2>
              <p className="login-card-subtitle">Enter your credentials to access the system</p>
            </div>

            <div className="form-field">
              <label htmlFor="username">Username</label>
              <input
                id="username"
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Enter your username"
                required
                autoComplete="username"
              />
            </div>

            <div className="form-field">
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                required
                autoComplete="current-password"
              />
            </div>

            {error && (
              <div className="error-box">
                <span>⚠️</span> {error}
              </div>
            )}

            <button type="submit" className="btn-primary btn-full" disabled={loading}>
              {loading ? <span className="loading-dots">Signing in</span> : 'Sign In →'}
            </button>

            <p className="login-card-note">
              Access is restricted to authorized personnel only.
            </p>
          </form>
        </div>
      </div>
    </div>
  );
}
