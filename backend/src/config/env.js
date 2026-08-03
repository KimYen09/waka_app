const path = require('node:path');

require('dotenv').config({ path: path.join(__dirname, '../../.env') });

function required(name, fallback) {
  const value = process.env[name] ?? fallback;
  if (value === undefined || value === '') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

module.exports = {
  port: Number(process.env.PORT || 3000),
  corsOrigin: process.env.CORS_ORIGIN || '*',
  jwtSecret: required('JWT_SECRET', 'development-only-change-me'),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  googleClientId: process.env.GOOGLE_CLIENT_ID || '',
  facebookAppId: process.env.FACEBOOK_APP_ID || '',
  facebookAppSecret: process.env.FACEBOOK_APP_SECRET || '',
  adminIdentifiers: String(process.env.ADMIN_IDENTIFIERS || '')
    .split(',')
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean),
  database: {
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'waka_demo',
    // MySQL container stores CURRENT_TIMESTAMP in UTC. Parse DATETIME as UTC
    // before serializing it to clients so local devices do not see a 7-hour
    // offset in Viet Nam.
    timezone: process.env.DB_TIMEZONE || 'Z',
  },
};
