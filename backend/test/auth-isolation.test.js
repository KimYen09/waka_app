const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const Module = require('node:module');

/// Các bài kiểm tra dưới đây khoá lại một lỗ hổng đã từng xảy ra: request
/// không kèm token hợp lệ được gán danh tính của "người dùng đầu tiên trong
/// bảng" (`SELECT id FROM users LIMIT 1`). Truy vấn đó không có ORDER BY nên
/// MySQL quét theo index UNIQUE(identifier) và trả về tài khoản đứng đầu theo
/// alphabet — một tài khoản `admin@...` sẽ đứng trước `guest_...`, khiến mọi
/// request ẩn danh mượn được quyền quản trị.
///
/// Middleware được nạp với một `pool` giả để test chạy không cần MySQL.

function loadWithFakePool(pool) {
  const middlewareDir = path.join(__dirname, '..', 'src', 'middleware');
  const dbPath = path.join(__dirname, '..', 'src', 'config', 'database.js');
  const originalLoad = Module._load;

  Module._load = function patched(request, parent, isMain) {
    if (parent && parent.filename && parent.filename.startsWith(middlewareDir)
      && request.includes('config/database')) {
      return pool;
    }
    return originalLoad(request, parent, isMain);
  };
  try {
    delete require.cache[require.resolve('../src/middleware/auth')];
    delete require.cache[require.resolve('../src/middleware/admin')];
    delete require.cache[dbPath];
    return {
      requireAuth: require('../src/middleware/auth'),
      requireAdmin: require('../src/middleware/admin'),
    };
  } finally {
    Module._load = originalLoad;
  }
}

function fakePool(handler) {
  return { execute: async (sql, params) => handler(sql, params) };
}

function runMiddleware(middleware, req) {
  return new Promise((resolve) => {
    middleware(req, {}, (error) => resolve(error));
  });
}

test('request không có token không được mượn danh tính tài khoản khác', async () => {
  const queries = [];
  const { requireAuth } = loadWithFakePool(fakePool(async (sql, params) => {
    queries.push({ sql, params });
    // Giả lập bảng users mà hàng đầu tiên theo index là một quản trị viên.
    if (sql.includes('WHERE identifier = ?')) {
      return params[0] === 'guest_demo_user' ? [[{ id: 77 }]] : [[]];
    }
    throw new Error(`Truy vấn không mong đợi: ${sql}`);
  }));

  const req = { get: () => '' };
  const error = await runMiddleware(requireAuth, req);

  assert.equal(error, undefined);
  assert.equal(req.user.id, 77, 'phải là tài khoản khách chuyên dụng');
  assert.equal(req.user.isGuest, true, 'phải được đánh dấu là phiên chưa xác thực');
  assert.ok(
    queries.every((q) => !/FROM users\s+LIMIT 1/i.test(q.sql)),
    'không được lấy "người dùng đầu tiên trong bảng" làm danh tính mặc định',
  );
});

test('token hỏng cũng chỉ rơi về phiên khách, không phải người dùng thật', async () => {
  const { requireAuth } = loadWithFakePool(fakePool(async (sql, params) => (
    sql.includes('WHERE identifier = ?') && params[0] === 'guest_demo_user'
      ? [[{ id: 5 }]]
      : [[]]
  )));

  const req = { get: () => 'Bearer token-gia-mao' };
  await runMiddleware(requireAuth, req);

  assert.equal(req.user.isGuest, true);
  assert.equal(req.user.id, 5);
});

test('phiên khách bị chặn khỏi trang quản trị dù tài khoản nền là admin', async () => {
  const { requireAdmin } = loadWithFakePool(fakePool(async () => [[
    { role: 'admin', accountStatus: 'active' },
  ]]));

  const req = { user: { id: 1, isGuest: true } };
  const error = await runMiddleware(requireAdmin, req);

  assert.ok(error, 'phải bị từ chối');
  assert.equal(error.status, 401);
});

test('admin đã đăng nhập thật vẫn vào được trang quản trị', async () => {
  const { requireAdmin } = loadWithFakePool(fakePool(async () => [[
    { role: 'admin', accountStatus: 'active' },
  ]]));

  const req = { user: { id: 1, isGuest: false } };
  const error = await runMiddleware(requireAdmin, req);

  assert.equal(error, undefined);
});
