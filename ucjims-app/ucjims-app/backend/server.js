require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { initPool, closePool } = require('./config/db');

const authRoutes = require('./routes/auth');
const caseRoutes = require('./routes/cases');
const evidenceRoutes = require('./routes/evidence');
const courtRoutes = require('./routes/court');

const app = express();
app.use(helmet());
app.use(cors()); // tighten this to your frontend's origin before any real deployment
app.use(express.json());

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api/auth', authRoutes);
app.use('/api/cases', caseRoutes);
app.use('/api/evidence', evidenceRoutes);
app.use('/api/court', courtRoutes);

// Fallback error handler - never leak stack traces/SQL to the client
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 4000;

initPool()
  .then(() => {
    app.listen(PORT, () => console.log(`UCJIMS API listening on port ${PORT}`));
  })
  .catch((err) => {
    console.error('Failed to initialize Oracle pool:', err.message);
    process.exit(1);
  });

process.on('SIGINT', async () => {
  await closePool();
  process.exit(0);
});
