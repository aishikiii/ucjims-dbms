require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { initPool, closePool, checkConnection } = require('./config/db');

const authRoutes = require('./routes/auth');
const caseRoutes = require('./routes/cases');
const evidenceRoutes = require('./routes/evidence');
const courtRoutes = require('./routes/court');

const app = express();

// Security headers via Helmet
app.use(
  helmet({
    contentSecurityPolicy: false, // delegated to reverse proxy in production
    crossOriginEmbedderPolicy: false,
  })
);

// Restrict CORS in production via environment variable
const allowedOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map((o) => o.trim())
  : '*';

app.use(
  cors({
    origin: allowedOrigins,
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Request payload limit to prevent resource exhaustion
app.use(express.json({ limit: '1mb' }));

// Health and readiness probe
app.get('/api/health', async (req, res) => {
  const dbHealth = await checkConnection();
  const isHealthy = dbHealth.status === 'connected';

  res.status(isHealthy ? 200 : 503).json({
    status: isHealthy ? 'healthy' : 'degraded',
    service: 'ucjims-backend',
    timestamp: new Date().toISOString(),
    database: dbHealth,
  });
});

// Mounted domain routes
app.use('/api/auth', authRoutes);
app.use('/api/cases', caseRoutes);
app.use('/api/evidence', evidenceRoutes);
app.use('/api/court', courtRoutes);

// Fallback 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Fallback error handler - never leak stack traces or SQL errors to client
app.use((err, req, res, next) => {
  console.error('Unhandled application error:', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 4000;

if (require.main === module) {
  initPool()
    .then(() => {
      app.listen(PORT, () => console.log(`UCJIMS API listening on port ${PORT}`));
    })
    .catch((err) => {
      console.error('Failed to initialize Oracle pool:', err.message);
      process.exit(1);
    });

  const handleShutdown = async () => {
    console.log('Gracefully closing Oracle connection pool...');
    await closePool();
    process.exit(0);
  };

  process.on('SIGINT', handleShutdown);
  process.on('SIGTERM', handleShutdown);
}

module.exports = app;
