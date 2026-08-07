const { randomUUID } = require('node:crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const env = require('../config/env');
const pool = require('../config/database');

const GUEST_IDENTIFIER = 'guest_demo_user';

let cachedGuestUserId = null;

/// Tài khoản khách dùng chung cho request không kèm token hợp lệ.
///
/// Phải tra đúng theo `identifier` cố định. Cách cũ (`SELECT id FROM users
/// LIMIT 1`) lấy về một hàng tuỳ ý: không có ORDER BY nên MySQL quét theo
/// index UNIQUE(identifier), tức trả về tài khoản đứng đầu theo ALPHABET.
/// Một tài khoản "admin@..." sẽ đứng trước "guest_...", nên mọi request ẩn
/// danh sẽ mượn luôn danh tính (và quyền) của quản trị viên.
async function getGuestUserId() {
  if (cachedGuestUserId) return cachedGuestUserId;

  const [rows] = await pool.execute(
    'SELECT id FROM users WHERE identifier = ? LIMIT 1',
    [GUEST_IDENTIFIER],
  );
  if (rows.length) {
    cachedGuestUserId = rows[0].id;
    return cachedGuestUserId;
  }

  // Mật khẩu ngẫu nhiên: không ai được đăng nhập trực tiếp vào tài khoản
  // khách dùng chung này.
  const passwordHash = await bcrypt.hash(randomUUID(), 12);
  await pool.execute(
    `INSERT INTO users (identifier, password_hash, display_name)
     VALUES (?, ?, ?)
     ON DUPLICATE KEY UPDATE identifier = VALUES(identifier)`,
    [GUEST_IDENTIFIER, passwordHash, 'Tài khoản Khách'],
  );
  const [created] = await pool.execute(
    'SELECT id FROM users WHERE identifier = ? LIMIT 1',
    [GUEST_IDENTIFIER],
  );
  cachedGuestUserId = created[0].id;
  return cachedGuestUserId;
}

async function requireAuth(req, res, next) {
  const authorization = req.get('authorization') || '';
  const [scheme, token] = authorization.split(' ');

  if (scheme === 'Bearer' && token && token !== 'guest_fallback_token') {
    try {
      const payload = jwt.verify(token, env.jwtSecret);
      const userId = Number(payload.sub);
      if (Number.isInteger(userId) && userId > 0) {
        req.user = { id: userId, identifier: payload.identifier, isGuest: false };
        return next();
      }
    } catch (_) {
      // Token hết hạn hoặc hỏng: rơi xuống tài khoản khách bên dưới để không
      // gián đoạn trải nghiệm duyệt sách.
    }
  }

  try {
    const guestId = await getGuestUserId();
    // `isGuest` đánh dấu danh tính CHƯA được xác thực. Mọi thao tác nhạy cảm
    // (quản trị, đổi mật khẩu...) phải từ chối phiên mang cờ này.
    req.user = { id: guestId, identifier: GUEST_IDENTIFIER, isGuest: true };
    return next();
  } catch (error) {
    return next(error);
  }
}

module.exports = requireAuth;
