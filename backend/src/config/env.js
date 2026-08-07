const path = require('node:path');

require('dotenv').config({ path: path.join(__dirname, '../../.env') });

/// Bí mật chỉ được phép có giá trị mặc định khi chạy dev.
///
/// Nếu luôn điền fallback thì bản production thiếu biến môi trường vẫn khởi
/// động bình thường bằng một chuỗi ai đọc mã nguồn cũng biết — đủ để tự ký
/// JWT cho bất kỳ tài khoản nào. Ở production phải dừng hẳn thay vì chạy tiếp
/// trong trạng thái không an toàn.
function requiredSecret(name, developmentFallback) {
  const value = process.env[name];
  if (value) return value;
  if (process.env.NODE_ENV === 'production') {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return developmentFallback;
}

module.exports = {
  port: Number(process.env.PORT || 3000),
  corsOrigin: process.env.CORS_ORIGIN || '*',
  jwtSecret: requiredSecret('JWT_SECRET', 'development-only-change-me'),
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  googleClientId: process.env.GOOGLE_CLIENT_ID || '',
  facebookAppId: process.env.FACEBOOK_APP_ID || '',
  facebookAppSecret: process.env.FACEBOOK_APP_SECRET || '',
  adminIdentifiers: String(process.env.ADMIN_IDENTIFIERS || '')
    .split(',')
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean),
  geminiApiKey: process.env.GEMINI_API_KEY || '',
  vnpay: {
    tmnCode: process.env.VNP_TMN_CODE || '',
    hashSecret: process.env.VNP_HASH_SECRET || '',
    url: process.env.VNP_URL || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
    returnUrl: process.env.VNP_RETURN_URL
      || `http://localhost:${process.env.PORT || 3000}/api/payments/vnpay/return`,
  },
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
