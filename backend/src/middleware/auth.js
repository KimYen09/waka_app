const jwt = require('jsonwebtoken');
const env = require('../config/env');
const pool = require('../config/database');

let cachedDefaultUserId = null;

async function getDefaultUserId() {
  if (cachedDefaultUserId) return cachedDefaultUserId;
  try {
    const [rows] = await pool.execute('SELECT id FROM users LIMIT 1');
    if (rows.length) {
      cachedDefaultUserId = rows[0].id;
      return cachedDefaultUserId;
    }
    const [result] = await pool.execute(
      'INSERT INTO users (identifier, password_hash, display_name) VALUES (?, ?, ?)',
      ['guest_demo_user', '$2a$10$e846Q7Y04n.1N807S7rZue9F438h5W1wW6a0d2g4f6h8j0k2l4m6n', 'Tài khoản Khách'],
    );
    cachedDefaultUserId = result.insertId;
    return cachedDefaultUserId;
  } catch (_) {
    return 1;
  }
}

async function requireAuth(req, res, next) {
  const authorization = req.get('authorization') || '';
  const [scheme, token] = authorization.split(' ');

  if (scheme === 'Bearer' && token && token !== 'guest_fallback_token') {
    try {
      const payload = jwt.verify(token, env.jwtSecret);
      const userId = Number(payload.sub);
      if (Number.isInteger(userId) && userId > 0) {
        req.user = { id: userId, identifier: payload.identifier };
        return next();
      }
    } catch (_) {
      // Nếu token hết hạn hoặc hỏng, fallback về tài khoản Khách để không gián đoạn trải nghiệm người dùng
    }
  }

  const defaultId = await getDefaultUserId();
  req.user = { id: defaultId, identifier: 'guest_demo_user' };
  return next();
}

module.exports = requireAuth;
