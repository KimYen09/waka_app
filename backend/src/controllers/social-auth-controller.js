const { randomUUID } = require('node:crypto');
const bcrypt = require('bcryptjs');
const { OAuth2Client } = require('google-auth-library');
const pool = require('../config/database');
const env = require('../config/env');
const HttpError = require('../utils/http-error');
const { createToken } = require('./auth-controller');

const googleClient = new OAuth2Client();

function requiredToken(value, provider) {
  const token = String(value || '').trim();
  if (!token) throw new HttpError(422, `Thiếu token đăng nhập ${provider}.`);
  return token;
}

async function google(req, res) {
  if (!env.googleClientId) {
    throw new HttpError(
      422,
      'Google Sign-In chưa được cấu hình. Hãy đặt GOOGLE_CLIENT_ID cho backend.',
    );
  }
  const idToken = requiredToken(req.body.idToken, 'Google');
  let payload;
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: env.googleClientId,
    });
    payload = ticket.getPayload();
  } catch (_) {
    throw new HttpError(401, 'Google ID token không hợp lệ hoặc đã hết hạn.');
  }
  if (!payload?.sub) throw new HttpError(401, 'Không đọc được tài khoản Google.');
  const user = await findOrCreateSocialUser({
    provider: 'google',
    providerUserId: payload.sub,
    email: payload.email_verified ? payload.email : null,
    displayName: payload.name,
  });
  res.json({ success: true, data: { user, token: createToken(user) } });
}

async function facebook(req, res) {
  if (!env.facebookAppId || !env.facebookAppSecret) {
    throw new HttpError(
      422,
      'Facebook Sign-In chưa được cấu hình. Hãy đặt FACEBOOK_APP_ID và FACEBOOK_APP_SECRET cho backend.',
    );
  }
  const inputToken = requiredToken(req.body.accessToken, 'Facebook');
  const appAccessToken = `${env.facebookAppId}|${env.facebookAppSecret}`;
  let tokenData;
  try {
    const debugUrl = new URL('https://graph.facebook.com/debug_token');
    debugUrl.searchParams.set('input_token', inputToken);
    debugUrl.searchParams.set('access_token', appAccessToken);
    const response = await fetch(debugUrl);
    const payload = await response.json();
    tokenData = payload.data;
  } catch (_) {
    throw new HttpError(502, 'Không thể xác minh token Facebook.');
  }
  if (!tokenData?.is_valid || String(tokenData.app_id) !== env.facebookAppId) {
    throw new HttpError(401, 'Facebook access token không hợp lệ hoặc đã hết hạn.');
  }

  let profile;
  try {
    const profileUrl = new URL(`https://graph.facebook.com/${tokenData.user_id}`);
    profileUrl.searchParams.set('fields', 'id,name,email');
    profileUrl.searchParams.set('access_token', inputToken);
    const response = await fetch(profileUrl);
    profile = await response.json();
  } catch (_) {
    throw new HttpError(502, 'Không thể lấy thông tin tài khoản Facebook.');
  }
  if (!profile?.id) throw new HttpError(401, 'Không đọc được tài khoản Facebook.');
  const user = await findOrCreateSocialUser({
    provider: 'facebook',
    providerUserId: profile.id,
    email: profile.email,
    displayName: profile.name,
  });
  res.json({ success: true, data: { user, token: createToken(user) } });
}

async function findOrCreateSocialUser({
  provider,
  providerUserId,
  email,
  displayName,
}) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [existing] = await connection.execute(
      `SELECT u.id, u.identifier, u.display_name AS displayName
       FROM social_accounts sa
       INNER JOIN users u ON u.id = sa.user_id
       WHERE sa.provider = ? AND sa.provider_user_id = ? LIMIT 1 FOR UPDATE`,
      [provider, providerUserId],
    );
    if (existing.length) {
      await connection.commit();
      return existing[0];
    }

    const identifier = `${provider}:${providerUserId}`;
    const passwordHash = await bcrypt.hash(randomUUID(), 12);
    const [result] = await connection.execute(
      'INSERT INTO users (identifier, password_hash, display_name) VALUES (?, ?, ?)',
      [identifier, passwordHash, String(displayName || '').trim() || null],
    );
    await connection.execute(
      `INSERT INTO social_accounts (user_id, provider, provider_user_id, email)
       VALUES (?, ?, ?, ?)`,
      [result.insertId, provider, providerUserId, String(email || '').trim() || null],
    );
    const user = {
      id: result.insertId,
      identifier,
      displayName: String(displayName || '').trim() || null,
    };
    await connection.commit();
    return user;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

module.exports = { google, facebook };
