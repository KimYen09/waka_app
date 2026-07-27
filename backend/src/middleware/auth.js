const jwt = require('jsonwebtoken');
const env = require('../config/env');
const HttpError = require('../utils/http-error');

function requireAuth(req, res, next) {
  const authorization = req.get('authorization') || '';
  const [scheme, token] = authorization.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return next(new HttpError(401, 'Bạn cần đăng nhập.'));
  }

  try {
    const payload = jwt.verify(token, env.jwtSecret);
    req.user = { id: Number(payload.sub), identifier: payload.identifier };
    return next();
  } catch (_) {
    return next(new HttpError(401, 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.'));
  }
}

module.exports = requireAuth;
