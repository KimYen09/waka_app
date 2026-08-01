const pool = require('../config/database');
const HttpError = require('../utils/http-error');

async function requireAdmin(req, res, next) {
  try {
    const [rows] = await pool.execute(
      `SELECT role, account_status AS accountStatus
       FROM users WHERE id = ? LIMIT 1`,
      [req.user.id],
    );
    const user = rows[0];
    if (!user) return next(new HttpError(401, 'Không tìm thấy tài khoản.'));
    if (user.accountStatus === 'locked') {
      return next(new HttpError(403, 'Tài khoản quản trị đã bị khóa.'));
    }
    if (user.role !== 'admin') {
      return next(new HttpError(403, 'Bạn không có quyền truy cập trang quản trị.'));
    }
    return next();
  } catch (error) {
    return next(error);
  }
}

module.exports = requireAdmin;
