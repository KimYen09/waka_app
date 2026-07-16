const cors = require('cors');
const express = require('express');
const env = require('./config/env');
const authRoutes = require('./routes/auth-routes');
const catalogRoutes = require('./routes/catalog-routes');
const { notFound, errorHandler } = require('./middleware/error-handler');

const app = express();

app.disable('x-powered-by');
app.use(cors({ origin: env.corsOrigin === '*' ? true : env.corsOrigin }));
app.use(express.json({ limit: '1mb' }));

app.get('/health', (req, res) => {
  res.json({ success: true, data: { status: 'ok' } });
});
app.use('/api/auth', authRoutes);
app.use('/api', catalogRoutes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
