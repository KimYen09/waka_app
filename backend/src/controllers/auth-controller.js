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
  const user = {
    id: result.insertId,
    identifier,
    displayName,
    role: 'reader',
    accountStatus: 'active',
  };

  res.status(201).json({ success: true, data: { user, token: createToken(user) } });
}

async function login(req, res) {
  const identifier = normalizeIdentifier(req.body.identifier);
  const password = String(req.body.password || '');
  validateCredentials(identifier, password);

  const [rows] = await pool.execute(
    `SELECT id, identifier, display_name AS displayName,
      role, account_status AS accountStatus, password_hash AS passwordHash
     FROM users WHERE identifier = ? LIMIT 1`,
    [identifier],
  );
  const user = rows[0];
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    throw new HttpError(401, 'Tài khoản hoặc mật khẩu không đúng.');
  }
  if (user.accountStatus === 'locked') {
    throw new HttpError(403, 'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.');
  }

  delete user.passwordHash;
  res.json({ success: true, data: { user, token: createToken(user) } });
}

async function me(req, res) {
  const [rows] = await pool.execute(
    `SELECT id, identifier, display_name AS displayName, role,
      account_status AS accountStatus, created_at AS createdAt
     FROM users WHERE id = ? LIMIT 1`,
    [req.user.id],
  );
  if (!rows.length) throw new HttpError(404, 'Không tìm thấy tài khoản.');
  res.json({ success: true, data: rows[0] });
}

async function changePassword(req, res) {
  // Phiên khách đại diện cho một tài khoản dùng chung chứ không phải người
  // đang gọi, nên không được phép đổi mật khẩu của tài khoản đó.
  if (req.user?.isGuest) {
    throw new HttpError(401, 'Vui lòng đăng nhập để đổi mật khẩu.');
  }
  const oldPassword = String(req.body.oldPassword || '');
  const newPassword = String(req.body.newPassword || '');
  if (newPassword.length < 6 || newPassword.length > 20) {
    throw new HttpError(422, 'Mật khẩu mới phải có từ 6 đến 20 ký tự.', {
      newPassword: 'Mật khẩu mới phải có từ 6 đến 20 ký tự.',
    });
  }
  if (newPassword === oldPassword) {
    throw new HttpError(422, 'Mật khẩu mới phải khác mật khẩu cũ.');
  }

  const [rows] = await pool.execute(
    'SELECT id, password_hash AS passwordHash FROM users WHERE id = ? LIMIT 1',
    [req.user.id],
  );
  const user = rows[0];
  if (!user) throw new HttpError(404, 'Không tìm thấy tài khoản.');
  if (!(await bcrypt.compare(oldPassword, user.passwordHash))) {
    throw new HttpError(401, 'Mật khẩu cũ không đúng.', {
      oldPassword: 'Mật khẩu cũ không đúng.',
    });
  }

  await pool.execute('UPDATE users SET password_hash = ? WHERE id = ?', [
    await bcrypt.hash(newPassword, 12),
    user.id,
  ]);
  res.json({ success: true, data: { changed: true } });
}

async function guestLogin(req, res) {
  const rawId = req.body.guestId ? String(req.body.guestId).trim() : 'demo_guest';
  const guestIdentifier = `guest_${rawId}`;

  let [rows] = await pool.execute(
    `SELECT id, identifier, display_name AS displayName,
      role, account_status AS accountStatus
     FROM users WHERE identifier = ? LIMIT 1`,
    [guestIdentifier],
  );
  let user = rows[0];
  if (!user) {
    const passwordHash = await bcrypt.hash('guest_secret_123', 10);
    const [result] = await pool.execute(
      'INSERT INTO users (identifier, password_hash, display_name) VALUES (?, ?, ?)',
      [guestIdentifier, passwordHash, 'Tài khoản Khách'],
    );
    user = {
      id: result.insertId,
      identifier: guestIdentifier,
      displayName: 'Tài khoản Khách',
      role: 'reader',
      accountStatus: 'active',
    };
  }

  res.json({ success: true, data: { user, token: createToken(user) } });
}

module.exports = { register, login, me, changePassword, guestLogin, createToken };
