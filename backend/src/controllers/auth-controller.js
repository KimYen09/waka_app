const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const env = require('../config/env');
const HttpError = require('../utils/http-error');

function normalizeIdentifier(value) {
  return String(value || '').trim().toLowerCase();
}

function validateCredentials(identifier, password) {
  const errors = {};
  if (!identifier) errors.identifier = 'Vui lòng nhập email hoặc số điện thoại.';
  if (password.length < 6) errors.password = 'Mật khẩu phải có ít nhất 6 ký tự.';
  if (Object.keys(errors).length) {
    throw new HttpError(422, 'Dữ liệu không hợp lệ.', errors);
  }
}

function createToken(user) {
  return jwt.sign(
    { identifier: user.identifier },
    env.jwtSecret,
    { subject: String(user.id), expiresIn: env.jwtExpiresIn },
  );
}

async function register(req, res) {
  const identifier = normalizeIdentifier(req.body.identifier);
  const password = String(req.body.password || '');
  const displayName = String(req.body.displayName || '').trim() || null;
  validateCredentials(identifier, password);

  const [existing] = await pool.execute(
    'SELECT id FROM users WHERE identifier = ? LIMIT 1',
    [identifier],
  );
  if (existing.length) throw new HttpError(409, 'Tài khoản đã tồn tại.');

  const passwordHash = await bcrypt.hash(password, 12);
  const [result] = await pool.execute(
    'INSERT INTO users (identifier, password_hash, display_name) VALUES (?, ?, ?)',
    [identifier, passwordHash, displayName],
  );
  const user = { id: result.insertId, identifier, displayName };

  res.status(201).json({ success: true, data: { user, token: createToken(user) } });
}

async function login(req, res) {
  const identifier = normalizeIdentifier(req.body.identifier);
  const password = String(req.body.password || '');
  validateCredentials(identifier, password);

  const [rows] = await pool.execute(
    'SELECT id, identifier, display_name AS displayName, password_hash AS passwordHash FROM users WHERE identifier = ? LIMIT 1',
    [identifier],
  );
  const user = rows[0];
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    throw new HttpError(401, 'Tài khoản hoặc mật khẩu không đúng.');
  }

  delete user.passwordHash;
  res.json({ success: true, data: { user, token: createToken(user) } });
}

async function me(req, res) {
  const [rows] = await pool.execute(
    'SELECT id, identifier, display_name AS displayName, created_at AS createdAt FROM users WHERE id = ? LIMIT 1',
    [req.user.id],
  );
  if (!rows.length) throw new HttpError(404, 'Không tìm thấy tài khoản.');
  res.json({ success: true, data: rows[0] });
}

module.exports = { register, login, me };
