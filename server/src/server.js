const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const path = require('path');
const { PORT } = require('./config');

const authRoutes = require('./routes/auth.routes');
const attendanceRoutes = require('./routes/attendance.routes');
const settingsRoutes = require('./routes/settings.routes');
const auditRoutes = require('./routes/audit.routes');
const reportsRoutes = require('./routes/reports.routes');

const app = express();

// Security and performance middleware
app.use(helmet({
  contentSecurityPolicy: false, // Allow CDN resources for charts & icons
  crossOriginEmbedderPolicy: false
}));
app.use(cors());
app.use(compression());
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true }));

// Serve frontend static assets
const publicPath = path.join(__dirname, '../../frontend/public');
app.use(express.static(publicPath));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/audit-logs', auditRoutes);
app.use('/api/reports', reportsRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'UP',
    system: 'BILLEL ATTENDANCE',
    version: '1.0.0',
    mode: '100% READ-ONLY',
    timestamp: new Date().toISOString()
  });
});

// SPA fallback
app.use((req, res, next) => {
  if (req.method === 'GET' && !req.path.startsWith('/api')) {
    return res.sendFile(path.join(publicPath, 'index.html'));
  }
  next();
});

// Global Sanitized Error Handler (No Stack Traces)
app.use((err, req, res, next) => {
  console.error('[Server Error]:', err.message);
  res.status(err.statusCode || 500).json({
    success: false,
    error: err.message || 'Une erreur interne est survenue sur le serveur.'
  });
});

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`====================================================`);
    console.log(`🚀 BILLEL ATTENDANCE - ZKTeco Dashboard`);
    console.log(`🔒 Mode: STRICT 100% READ-ONLY`);
    console.log(`🌐 Server running at: http://localhost:${PORT}`);
    console.log(`====================================================`);
  });
}

module.exports = app;
