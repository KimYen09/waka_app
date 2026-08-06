const pool = require('../config/database');
const HttpError = require('../utils/http-error');
const { applyPaymentStatus } = require('../services/payment-outcomes');

const bookStatuses = new Set(['draft', 'pending', 'approved', 'rejected']);
const applicationStatuses = new Set(['pending', 'approved', 'rejected']);
const orderStatuses = new Set([
  'payment_review',
  'confirmed',
  'packing',
  'in_transit',
  'at_hub',
  'out_for_delivery',
  'delivered',
  'cancelled',
]);
const shippingStatuses = new Set([
  'confirmed',
  'packing',
  'in_transit',
  'at_hub',
  'out_for_delivery',
  'delivered',
  'cancelled',
]);
const paymentStatuses = new Set([
  'pending',
  'proof_submitted',
  'paid',
  'failed',
  'refunded',
]);
const userRoles = new Set(['reader', 'author', 'admin']);
const accountStatuses = new Set(['active', 'locked']);

function text(value, maxLength = 1000) {
  return String(value || '').trim().slice(0, maxLength);
}

function optionalId(value) {
  const id = Number.parseInt(value, 10);
  return Number.isInteger(id) && id > 0 ? id : null;
}

function price(value) {
  const amount = Number(value);
  if (!Number.isFinite(amount) || amount < 0 || amount > 9999999999) {
    throw new HttpError(422, 'Giá truyện không hợp lệ.');
  }
  return Math.round(amount);
}

function discount(value) {
  const amount = Number.parseInt(value, 10) || 0;
  if (amount < 0 || amount > 100) {
    throw new HttpError(422, 'Phần trăm giảm giá phải từ 0 đến 100.');
  }
  return amount;
}

function mapAdminBook(row) {
  return {
    id: row.id,
    title: row.title,
    author: row.author,
    authorId: row.authorId,
    authorDisplayName: row.authorDisplayName,
    description: row.description || '',
    imageUrl: row.imageUrl || '',
    sourceUrl: row.sourceUrl || '',
    price: Number(row.price || 0),
    discountPercent: Number(row.discountPercent || 0),
    isFeatured: Boolean(row.isFeatured),
    moderationStatus: row.moderationStatus,
    moderationNote: row.moderationNote || '',
    isLocked: Boolean(row.isLocked),
    lockReason: row.lockReason || '',
    categoryId: row.categoryId,
    categoryName: row.categoryName,
    submittedBy: row.submittedBy,
    submittedByName: row.submittedByName,
    reviewedBy: row.reviewedBy,
    reviewedByName: row.reviewedByName,
    reviewedAt: row.reviewedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

const adminBookSelect = `
  SELECT b.id, b.title, b.author, b.author_id AS authorId,
    a.display_name AS authorDisplayName, b.description,
    b.image_url AS imageUrl, b.source_url AS sourceUrl,
    b.price, b.discount_percent AS discountPercent,
    b.is_featured AS isFeatured,
    b.moderation_status AS moderationStatus,
    b.moderation_note AS moderationNote,
    b.is_locked AS isLocked, b.lock_reason AS lockReason,
    b.category_id AS categoryId, c.name AS categoryName,
    b.submitted_by AS submittedBy, submitter.display_name AS submittedByName,
    b.reviewed_by AS reviewedBy, reviewer.display_name AS reviewedByName,
    b.reviewed_at AS reviewedAt, b.created_at AS createdAt,
    b.updated_at AS updatedAt
  FROM books b
  LEFT JOIN authors a ON a.id = b.author_id
  LEFT JOIN categories c ON c.id = b.category_id
  LEFT JOIN users submitter ON submitter.id = b.submitted_by
  LEFT JOIN users reviewer ON reviewer.id = b.reviewed_by`;

async function dashboard(req, res) {
  try {
    const [
      [bookCounts],
      [applicationCounts],
      [authorCounts],
      [orderCounts],
      [paymentCounts],
      [userCounts],
    ] = await Promise.all([
      pool.query(
        `SELECT COUNT(*) AS total,
          SUM(moderation_status = 'pending') AS pending,
          SUM(moderation_status = 'approved') AS approved,
          SUM(is_locked = TRUE) AS locked
         FROM books`,
      ).catch(() => [[{ total: 0, pending: 0, approved: 0, locked: 0 }]]),
      pool.query(
        `SELECT COUNT(*) AS total,
          SUM(status = 'pending') AS pending,
          SUM(status = 'approved') AS approved,
          SUM(status = 'rejected') AS rejected
         FROM author_applications`,
      ).catch(() => [[{ total: 0, pending: 0, approved: 0, rejected: 0 }]]),
      pool.query(
        `SELECT COUNT(*) AS total,
          SUM(status = 'active') AS active,
          SUM(status = 'locked') AS locked
         FROM authors`,
      ).catch(() => [[{ total: 0, active: 0, locked: 0 }]]),
      pool.query(
        `SELECT COUNT(*) AS total,
          SUM(status = 'payment_review') AS pending,
          SUM(status = 'delivered') AS paid,
          SUM(status = 'cancelled') AS cancelled,
          COALESCE(SUM(IF(status = 'delivered', total, 0)), 0) AS revenue
         FROM orders`,
      ).catch(() => [[{ total: 0, pending: 0, paid: 0, cancelled: 0, revenue: 0 }]]),
      pool.query(
        `SELECT COUNT(*) AS total,
          SUM(status = 'pending') AS pending,
          SUM(status = 'paid') AS paid,
          SUM(status = 'failed') AS failed,
          SUM(status = 'refunded') AS refunded,
          COALESCE(SUM(IF(status = 'paid', amount, 0)), 0) AS received
         FROM payments`,
      ).catch(() => [[{ total: 0, pending: 0, paid: 0, failed: 0, refunded: 0, received: 0 }]]),
      pool.query(
        `SELECT COUNT(*) AS total,
          SUM(role = 'reader') AS readers,
          SUM(role = 'author') AS authors,
          SUM(role = 'admin') AS admins,
          SUM(account_status = 'locked') AS locked
         FROM users`,
      ).catch(() => [[{ total: 0, readers: 0, authors: 0, admins: 0, locked: 0 }]]),
    ]);
    const numberMap = (row) => Object.fromEntries(
      Object.entries(row || {}).map(([key, value]) => [key, Number(value || 0)]),
    );
    res.json({
      success: true,
      data: {
        books: numberMap(bookCounts[0]),
        authorApplications: numberMap(applicationCounts[0]),
        authors: numberMap(authorCounts[0]),
        orders: numberMap(orderCounts[0]),
        payments: numberMap(paymentCounts[0]),
        users: numberMap(userCounts[0]),
      },
    });
  } catch (err) {
    res.json({
      success: true,
      data: {
        books: {},
        authorApplications: {},
        authors: {},
        orders: {},
        payments: {},
        users: {},
      },
    });
  }
}

async function listOrders(req, res) {
  const status = text(req.query.status, 20);
  const search = text(req.query.search, 120);
  const filters = [];
  const params = [];
  if (status && orderStatuses.has(status)) {
    filters.push('o.status = ?');
    params.push(status);
  }
  if (search) {
    filters.push('(u.identifier LIKE ? OR u.display_name LIKE ? OR CAST(o.id AS CHAR) = ?)');
    params.push(`%${search}%`, `%${search}%`, search.replace(/^#/, ''));
  }
  const where = filters.length ? ` WHERE ${filters.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `SELECT o.id, o.order_code AS orderCode, o.user_id AS userId,
      u.identifier AS account, u.display_name AS customerName,
      o.payment_method AS paymentMethod, p.status AS paymentStatus,
      p.id AS paymentId, o.status, o.total,
      o.shipping_recipient AS shippingRecipient,
      o.shipping_phone AS shippingPhone,
      o.shipping_address AS shippingAddress,
      o.created_at AS createdAt, o.updated_at AS updatedAt,
      COUNT(oi.book_id) AS lineCount,
      COALESCE(SUM(oi.quantity), 0) AS itemCount,
      GROUP_CONCAT(CONCAT(b.title, ' ×', oi.quantity)
        ORDER BY b.title SEPARATOR '|||') AS itemSummary
     FROM orders o
     INNER JOIN users u ON u.id = o.user_id
     LEFT JOIN payments p ON p.order_id = o.id
     LEFT JOIN order_items oi ON oi.order_id = o.id
     LEFT JOIN books b ON b.id = oi.book_id${where}
     GROUP BY o.id, o.order_code, o.user_id, u.identifier, u.display_name,
       o.payment_method, p.status, p.id, o.status, o.total,
       o.shipping_recipient, o.shipping_phone, o.shipping_address,
       o.created_at, o.updated_at
     ORDER BY o.id DESC LIMIT 200`,
    params,
  );
  const orderIds = rows.map((row) => row.id);
  let events = [];
  if (orderIds.length) {
    const placeholders = orderIds.map(() => '?').join(',');
    [events] = await pool.execute(
      `SELECT se.id, se.order_id AS orderId, se.status, se.location,
        se.description, creator.display_name AS createdByName,
        se.created_at AS createdAt
       FROM shipping_events se
       LEFT JOIN users creator ON creator.id = se.created_by
       WHERE se.order_id IN (${placeholders})
       ORDER BY se.created_at, se.id`,
      orderIds,
    );
  }
  res.json({
    success: true,
    data: rows.map((row) => ({
      ...row,
      total: Number(row.total || 0),
      lineCount: Number(row.lineCount || 0),
      itemCount: Number(row.itemCount || 0),
      items: row.itemSummary ? String(row.itemSummary).split('|||') : [],
      shippingEvents: events.filter((event) => event.orderId === row.id),
      itemSummary: undefined,
    })),
  });
}

async function updateOrderStatus(req, res) {
  const id = optionalId(req.params.id);
  const status = text(req.body.status, 20);
  if (!id) throw new HttpError(400, 'Mã đơn hàng không hợp lệ.');
  if (!orderStatuses.has(status)) {
    throw new HttpError(422, 'Trạng thái đơn hàng không hợp lệ.');
  }
  const [result] = await pool.execute(
    'UPDATE orders SET status = ? WHERE id = ?',
    [status, id],
  );
  if (!result.affectedRows) throw new HttpError(404, 'Không tìm thấy đơn hàng.');
  await pool.execute(
    `INSERT INTO shipping_events
      (order_id, status, location, description, created_by)
     VALUES (?, ?, '', ?, ?)`,
    [id, status, `Quản trị viên cập nhật: ${status}.`, req.user.id],
  );
  res.json({ success: true, data: { id, status } });
}

async function addShippingEvent(req, res) {
  const id = optionalId(req.params.id);
  const status = text(req.body.status, 40);
  const location = text(req.body.location, 255);
  const description = text(req.body.description, 500);
  if (!id) throw new HttpError(400, 'Mã đơn hàng không hợp lệ.');
  if (!shippingStatuses.has(status)) {
    throw new HttpError(422, 'Trạng thái vận chuyển không hợp lệ.');
  }
  if (!location && status !== 'cancelled') {
    throw new HttpError(422, 'Vui lòng nhập vị trí hoặc kho vận hiện tại.');
  }
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [orders] = await connection.execute(
      `SELECT o.payment_method AS paymentMethod, p.status AS paymentStatus
       FROM orders o LEFT JOIN payments p ON p.order_id = o.id
       WHERE o.id = ? LIMIT 1 FOR UPDATE`,
      [id],
    );
    if (!orders.length) throw new HttpError(404, 'Không tìm thấy đơn hàng.');
    const order = orders[0];
    if (order.paymentMethod === 'bank_qr' && order.paymentStatus !== 'paid' && status !== 'cancelled') {
      throw new HttpError(422, 'Cần xác nhận thanh toán QR trước khi giao hàng.');
    }
    await connection.execute('UPDATE orders SET status = ? WHERE id = ?', [status, id]);
    await connection.execute(
      `INSERT INTO shipping_events
        (order_id, status, location, description, created_by)
       VALUES (?, ?, ?, ?, ?)`,
      [id, status, location, description || `Cập nhật ${status}.`, req.user.id],
    );
    if (status === 'delivered' && order.paymentMethod === 'cod') {
      await connection.execute(
        `UPDATE payments SET status = 'paid', paid_at = COALESCE(paid_at, NOW())
         WHERE order_id = ?`,
        [id],
      );
    }
    if (status === 'cancelled') {
      await connection.execute(
        `UPDATE payments SET status = 'failed'
         WHERE order_id = ? AND status IN ('pending', 'proof_submitted')`,
        [id],
      );
    }
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
  res.status(201).json({ success: true, data: { orderId: id, status, location } });
}

async function listPayments(req, res) {
  const status = text(req.query.status, 20);
  const search = text(req.query.search, 120);
  const filters = [];
  const params = [];
  if (status && paymentStatuses.has(status)) {
    filters.push('p.status = ?');
    params.push(status);
  }
  if (search) {
    filters.push(`(u.identifier LIKE ? OR u.display_name LIKE ?
      OR p.transaction_ref LIKE ? OR CAST(p.id AS CHAR) = ?)`);
    params.push(
      `%${search}%`,
      `%${search}%`,
      `%${search}%`,
      search.replace(/^#/, ''),
    );
  }
  const where = filters.length ? ` WHERE ${filters.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `SELECT p.id, p.user_id AS userId, u.identifier AS account,
      u.display_name AS customerName, p.order_id AS orderId,
      p.membership_id AS membershipId, mp.title AS membershipTitle,
      p.provider, p.transaction_ref AS transactionRef, p.amount,
      p.status, p.paid_at AS paidAt, p.created_at AS createdAt
     FROM payments p
     INNER JOIN users u ON u.id = p.user_id
     LEFT JOIN user_memberships um ON um.id = p.membership_id
     LEFT JOIN membership_plans mp ON mp.id = um.plan_id${where}
     ORDER BY p.id DESC LIMIT 200`,
    params,
  );
  res.json({
    success: true,
    data: rows.map((row) => ({ ...row, amount: Number(row.amount || 0) })),
  });
}

async function updatePaymentStatus(req, res) {
  const id = optionalId(req.params.id);
  const status = text(req.body.status, 20);
  if (!id) throw new HttpError(400, 'Mã giao dịch không hợp lệ.');
  if (!paymentStatuses.has(status)) {
    throw new HttpError(422, 'Trạng thái giao dịch không hợp lệ.');
  }
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const payment = await applyPaymentStatus(connection, {
      paymentId: id,
      status,
      actorUserId: req.user.id,
    });
    if (!payment) throw new HttpError(404, 'Không tìm thấy giao dịch.');
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
  res.json({ success: true, data: { id, status } });
}

async function listUsers(req, res) {
  const role = text(req.query.role, 20);
  const status = text(req.query.status, 20);
  const search = text(req.query.search, 120);
  const filters = [];
  const params = [];
  if (role && userRoles.has(role)) {
    filters.push('u.role = ?');
    params.push(role);
  }
  if (status && accountStatuses.has(status)) {
    filters.push('u.account_status = ?');
    params.push(status);
  }
  if (search) {
    filters.push('(u.identifier LIKE ? OR u.display_name LIKE ?)');
    params.push(`%${search}%`, `%${search}%`);
  }
  const where = filters.length ? ` WHERE ${filters.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `SELECT u.id, u.identifier, u.display_name AS displayName,
      u.role, u.account_status AS accountStatus, u.created_at AS createdAt,
      (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id) AS orderCount,
      (SELECT COUNT(*) FROM payments p WHERE p.user_id = u.id) AS paymentCount,
      (SELECT COALESCE(SUM(p.amount), 0) FROM payments p
       WHERE p.user_id = u.id AND p.status = 'paid') AS totalSpent
     FROM users u${where} ORDER BY u.id DESC LIMIT 300`,
    params,
  );
  res.json({
    success: true,
    data: rows.map((row) => ({
      ...row,
      orderCount: Number(row.orderCount || 0),
      paymentCount: Number(row.paymentCount || 0),
      totalSpent: Number(row.totalSpent || 0),
    })),
  });
}

async function updateUser(req, res) {
  const id = optionalId(req.params.id);
  if (!id) throw new HttpError(400, 'Mã tài khoản không hợp lệ.');
  if (id === Number(req.user.id)) {
    throw new HttpError(422, 'Không thể tự thay đổi quyền hoặc khóa tài khoản đang đăng nhập.');
  }
  const [rows] = await pool.execute(
    'SELECT role, account_status AS accountStatus FROM users WHERE id = ? LIMIT 1',
    [id],
  );
  if (!rows.length) throw new HttpError(404, 'Không tìm thấy tài khoản.');
  const role = req.body.role === undefined ? rows[0].role : text(req.body.role, 20);
  const accountStatus = req.body.accountStatus === undefined
    ? rows[0].accountStatus
    : text(req.body.accountStatus, 20);
  if (!userRoles.has(role) || !accountStatuses.has(accountStatus)) {
    throw new HttpError(422, 'Quyền hoặc trạng thái tài khoản không hợp lệ.');
  }
  await pool.execute(
    'UPDATE users SET role = ?, account_status = ? WHERE id = ?',
    [role, accountStatus, id],
  );
  res.json({ success: true, data: { id, role, accountStatus } });
}

async function listBooks(req, res) {
  const page = Math.max(Number.parseInt(req.query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 30, 1), 100);
  const offset = (page - 1) * limit;
  const search = text(req.query.search, 120);
  const status = text(req.query.status, 20);
  const locked = req.query.locked;
  const filters = [];
  const params = [];
  if (search) {
    filters.push('(b.title LIKE ? OR b.author LIKE ? OR a.display_name LIKE ?)');
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }
  if (status && bookStatuses.has(status)) {
    filters.push('b.moderation_status = ?');
    params.push(status);
  }
  if (locked === 'true' || locked === 'false') {
    filters.push('b.is_locked = ?');
    params.push(locked === 'true');
  }
  const where = filters.length ? ` WHERE ${filters.join(' AND ')}` : '';
  const [countRows] = await pool.execute(
    `SELECT COUNT(*) AS total FROM books b
     LEFT JOIN authors a ON a.id = b.author_id${where}`,
    params,
  );
  const [rows] = await pool.query(
    `${adminBookSelect}${where}
     ORDER BY (b.moderation_status = 'pending') DESC, b.updated_at DESC
     LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );
  const total = Number(countRows[0].total);
  res.json({
    success: true,
    data: rows.map(mapAdminBook),
    meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
  });
}

async function createBook(req, res) {
  const title = text(req.body.title, 255);
  const author = text(req.body.author, 160);
  if (!title) throw new HttpError(422, 'Vui lòng nhập tên truyện.');
  if (!author) throw new HttpError(422, 'Vui lòng nhập tên tác giả.');
  const moderationStatus = bookStatuses.has(req.body.moderationStatus)
    ? req.body.moderationStatus
    : 'approved';
  const reviewed = moderationStatus === 'approved' || moderationStatus === 'rejected';
  const [result] = await pool.execute(
    `INSERT INTO books
      (category_id, author_id, title, author, description, image_url, source_url,
       price, discount_percent, is_featured, moderation_status, submitted_by,
       reviewed_by, reviewed_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      optionalId(req.body.categoryId),
      optionalId(req.body.authorId),
      title,
      author,
      text(req.body.description, 20000) || null,
      text(req.body.imageUrl, 4000) || null,
      text(req.body.sourceUrl, 4000) || null,
      price(req.body.price || 0),
      discount(req.body.discountPercent),
      Boolean(req.body.isFeatured),
      moderationStatus,
      req.user.id,
      reviewed ? req.user.id : null,
      reviewed ? new Date() : null,
    ],
  );
  const [rows] = await pool.execute(`${adminBookSelect} WHERE b.id = ?`, [result.insertId]);
  res.status(201).json({ success: true, data: mapAdminBook(rows[0]) });
}

async function updateBook(req, res) {
  const id = optionalId(req.params.id);
  if (!id) throw new HttpError(400, 'Mã truyện không hợp lệ.');
  const [rows] = await pool.execute('SELECT * FROM books WHERE id = ? LIMIT 1', [id]);
  const current = rows[0];
  if (!current) throw new HttpError(404, 'Không tìm thấy truyện.');
  const title = req.body.title === undefined ? current.title : text(req.body.title, 255);
  const author = req.body.author === undefined ? current.author : text(req.body.author, 160);
  if (!title || !author) throw new HttpError(422, 'Tên truyện và tác giả không được để trống.');
  await pool.execute(
    `UPDATE books SET category_id = ?, author_id = ?, title = ?, author = ?,
      description = ?, image_url = ?, source_url = ?, price = ?,
      discount_percent = ?, is_featured = ? WHERE id = ?`,
    [
      req.body.categoryId === undefined ? current.category_id : optionalId(req.body.categoryId),
      req.body.authorId === undefined ? current.author_id : optionalId(req.body.authorId),
      title,
      author,
      req.body.description === undefined
        ? current.description
        : text(req.body.description, 20000) || null,
      req.body.imageUrl === undefined
        ? current.image_url
        : text(req.body.imageUrl, 4000) || null,
      req.body.sourceUrl === undefined
        ? current.source_url
        : text(req.body.sourceUrl, 4000) || null,
      req.body.price === undefined ? current.price : price(req.body.price),
      req.body.discountPercent === undefined
        ? current.discount_percent
        : discount(req.body.discountPercent),
      req.body.isFeatured === undefined
        ? current.is_featured
        : Boolean(req.body.isFeatured),
      id,
    ],
  );
  const [updated] = await pool.execute(`${adminBookSelect} WHERE b.id = ?`, [id]);
  res.json({ success: true, data: mapAdminBook(updated[0]) });
}

async function moderateBook(req, res) {
  const id = optionalId(req.params.id);
  const status = text(req.body.status, 20);
  if (!id) throw new HttpError(400, 'Mã truyện không hợp lệ.');
  if (!bookStatuses.has(status) || status === 'draft') {
    throw new HttpError(422, 'Trạng thái kiểm duyệt không hợp lệ.');
  }
  const [result] = await pool.execute(
    `UPDATE books SET moderation_status = ?, moderation_note = ?,
      reviewed_by = ?, reviewed_at = NOW()
     WHERE id = ?`,
    [status, text(req.body.note, 500) || null, req.user.id, id],
  );
  if (!result.affectedRows) throw new HttpError(404, 'Không tìm thấy truyện.');
  const [rows] = await pool.execute(`${adminBookSelect} WHERE b.id = ?`, [id]);
  res.json({ success: true, data: mapAdminBook(rows[0]) });
}

async function lockBook(req, res) {
  const id = optionalId(req.params.id);
  if (!id) throw new HttpError(400, 'Mã truyện không hợp lệ.');
  const locked = Boolean(req.body.locked);
  const reason = locked ? text(req.body.reason, 500) : '';
  if (locked && !reason) throw new HttpError(422, 'Vui lòng nhập lý do khóa truyện.');
  const [result] = await pool.execute(
    'UPDATE books SET is_locked = ?, lock_reason = ? WHERE id = ?',
    [locked, reason || null, id],
  );
  if (!result.affectedRows) throw new HttpError(404, 'Không tìm thấy truyện.');
  const [rows] = await pool.execute(`${adminBookSelect} WHERE b.id = ?`, [id]);
  res.json({ success: true, data: mapAdminBook(rows[0]) });
}

function mapApplication(row) {
  return {
    id: row.id,
    userId: row.userId,
    account: row.account,
    realName: row.realName,
    penName: row.penName || '',
    email: row.email,
    phone: row.phone || '',
    bio: row.bio || '',
    identityDocumentUrl: row.identityDocumentUrl || '',
    portfolioUrl: row.portfolioUrl || '',
    status: row.status,
    reviewNote: row.reviewNote || '',
    reviewedByName: row.reviewedByName,
    reviewedAt: row.reviewedAt,
    createdAt: row.createdAt,
  };
}

const applicationSelect = `
  SELECT aa.id, aa.user_id AS userId, u.identifier AS account,
    aa.real_name AS realName, aa.pen_name AS penName, aa.email, aa.phone,
    aa.bio, aa.identity_document_url AS identityDocumentUrl,
    aa.portfolio_url AS portfolioUrl, aa.status,
    aa.review_note AS reviewNote, reviewer.display_name AS reviewedByName,
    aa.reviewed_at AS reviewedAt, aa.created_at AS createdAt
  FROM author_applications aa
  INNER JOIN users u ON u.id = aa.user_id
  LEFT JOIN users reviewer ON reviewer.id = aa.reviewed_by`;

async function submitAuthorApplication(req, res) {
  const realName = text(req.body.realName, 160);
  const email = text(req.body.email, 255).toLowerCase();
  if (!realName || !email) {
    throw new HttpError(422, 'Họ tên và email là bắt buộc.');
  }
  await pool.execute(
    `INSERT INTO author_applications
      (user_id, real_name, pen_name, email, phone, bio,
       identity_document_url, portfolio_url, status, review_note,
       reviewed_by, reviewed_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', NULL, NULL, NULL)
     ON DUPLICATE KEY UPDATE real_name = VALUES(real_name),
       pen_name = VALUES(pen_name), email = VALUES(email), phone = VALUES(phone),
       bio = VALUES(bio), identity_document_url = VALUES(identity_document_url),
       portfolio_url = VALUES(portfolio_url), status = 'pending',
       review_note = NULL, reviewed_by = NULL, reviewed_at = NULL`,
    [
      req.user.id,
      realName,
      text(req.body.penName, 160),
      email,
      text(req.body.phone, 30),
      text(req.body.bio, 10000) || null,
      text(req.body.identityDocumentUrl, 4000) || null,
      text(req.body.portfolioUrl, 4000) || null,
    ],
  );
  const [rows] = await pool.execute(`${applicationSelect} WHERE aa.user_id = ?`, [req.user.id]);
  res.status(201).json({ success: true, data: mapApplication(rows[0]) });
}

async function myAuthorApplication(req, res) {
  const [rows] = await pool.execute(`${applicationSelect} WHERE aa.user_id = ?`, [req.user.id]);
  res.json({ success: true, data: rows.length ? mapApplication(rows[0]) : null });
}

async function listAuthorApplications(req, res) {
  const status = text(req.query.status, 20);
  const params = [];
  let where = '';
  if (status && applicationStatuses.has(status)) {
    where = ' WHERE aa.status = ?';
    params.push(status);
  }
  const [rows] = await pool.execute(
    `${applicationSelect}${where}
     ORDER BY (aa.status = 'pending') DESC, aa.updated_at DESC`,
    params,
  );
  res.json({ success: true, data: rows.map(mapApplication) });
}

async function reviewAuthorApplication(req, res) {
  const id = optionalId(req.params.id);
  const status = text(req.body.status, 20);
  if (!id) throw new HttpError(400, 'Mã hồ sơ không hợp lệ.');
  if (status !== 'approved' && status !== 'rejected') {
    throw new HttpError(422, 'Quyết định duyệt không hợp lệ.');
  }
  const note = text(req.body.note, 500);
  if (status === 'rejected' && !note) {
    throw new HttpError(422, 'Vui lòng nhập lý do từ chối.');
  }
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [applications] = await connection.execute(
      'SELECT * FROM author_applications WHERE id = ? LIMIT 1 FOR UPDATE',
      [id],
    );
    const application = applications[0];
    if (!application) throw new HttpError(404, 'Không tìm thấy hồ sơ tác giả.');
    await connection.execute(
      `UPDATE author_applications SET status = ?, review_note = ?,
       reviewed_by = ?, reviewed_at = NOW() WHERE id = ?`,
      [status, note || null, req.user.id, id],
    );
    if (status === 'approved') {
      await connection.execute(
        `INSERT INTO authors
          (user_id, display_name, pen_name, email, phone, bio,
           status, lock_reason, approved_by, approved_at)
         VALUES (?, ?, ?, ?, ?, ?, 'active', NULL, ?, NOW())
         ON DUPLICATE KEY UPDATE display_name = VALUES(display_name),
           pen_name = VALUES(pen_name), email = VALUES(email),
           phone = VALUES(phone), bio = VALUES(bio), status = 'active',
           lock_reason = NULL, approved_by = VALUES(approved_by),
           approved_at = NOW()`,
        [
          application.user_id,
          application.real_name,
          application.pen_name,
          application.email,
          application.phone,
          application.bio,
          req.user.id,
        ],
      );
      await connection.execute(
        "UPDATE users SET role = 'author' WHERE id = ? AND role <> 'admin'",
        [application.user_id],
      );
    }
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
  const [rows] = await pool.execute(`${applicationSelect} WHERE aa.id = ?`, [id]);
  res.json({ success: true, data: mapApplication(rows[0]) });
}

function mapAuthor(row) {
  return {
    id: row.id,
    userId: row.userId,
    account: row.account,
    displayName: row.displayName,
    penName: row.penName || '',
    email: row.email || '',
    phone: row.phone || '',
    bio: row.bio || '',
    avatarUrl: row.avatarUrl || '',
    status: row.status,
    lockReason: row.lockReason || '',
    approvedByName: row.approvedByName,
    approvedAt: row.approvedAt,
    bookCount: Number(row.bookCount || 0),
    createdAt: row.createdAt,
  };
}

const authorSelect = `
  SELECT a.id, a.user_id AS userId, u.identifier AS account,
    a.display_name AS displayName, a.pen_name AS penName, a.email, a.phone,
    a.bio, a.avatar_url AS avatarUrl, a.status,
    a.lock_reason AS lockReason, approver.display_name AS approvedByName,
    a.approved_at AS approvedAt, a.created_at AS createdAt,
    (SELECT COUNT(*) FROM books b WHERE b.author_id = a.id) AS bookCount
  FROM authors a
  LEFT JOIN users u ON u.id = a.user_id
  LEFT JOIN users approver ON approver.id = a.approved_by`;

async function listAuthors(req, res) {
  const search = text(req.query.search, 120);
  const status = text(req.query.status, 20);
  const filters = [];
  const params = [];
  if (search) {
    filters.push('(a.display_name LIKE ? OR a.pen_name LIKE ? OR a.email LIKE ?)');
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }
  if (status === 'active' || status === 'locked') {
    filters.push('a.status = ?');
    params.push(status);
  }
  const where = filters.length ? ` WHERE ${filters.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `${authorSelect}${where} ORDER BY a.updated_at DESC`,
    params,
  );
  res.json({ success: true, data: rows.map(mapAuthor) });
}

async function updateAuthor(req, res) {
  const id = optionalId(req.params.id);
  if (!id) throw new HttpError(400, 'Mã tác giả không hợp lệ.');
  const [rows] = await pool.execute('SELECT * FROM authors WHERE id = ? LIMIT 1', [id]);
  const current = rows[0];
  if (!current) throw new HttpError(404, 'Không tìm thấy tác giả.');
  const displayName = req.body.displayName === undefined
    ? current.display_name
    : text(req.body.displayName, 160);
  if (!displayName) throw new HttpError(422, 'Tên tác giả không được để trống.');
  await pool.execute(
    `UPDATE authors SET display_name = ?, pen_name = ?, email = ?, phone = ?,
      bio = ?, avatar_url = ? WHERE id = ?`,
    [
      displayName,
      req.body.penName === undefined ? current.pen_name : text(req.body.penName, 160),
      req.body.email === undefined ? current.email : text(req.body.email, 255),
      req.body.phone === undefined ? current.phone : text(req.body.phone, 30),
      req.body.bio === undefined ? current.bio : text(req.body.bio, 10000) || null,
      req.body.avatarUrl === undefined
        ? current.avatar_url
        : text(req.body.avatarUrl, 4000) || null,
      id,
    ],
  );
  const [updated] = await pool.execute(`${authorSelect} WHERE a.id = ?`, [id]);
  res.json({ success: true, data: mapAuthor(updated[0]) });
}

async function lockAuthor(req, res) {
  const id = optionalId(req.params.id);
  if (!id) throw new HttpError(400, 'Mã tác giả không hợp lệ.');
  const locked = Boolean(req.body.locked);
  const reason = locked ? text(req.body.reason, 500) : '';
  if (locked && !reason) throw new HttpError(422, 'Vui lòng nhập lý do khóa tác giả.');
  const [result] = await pool.execute(
    'UPDATE authors SET status = ?, lock_reason = ? WHERE id = ?',
    [locked ? 'locked' : 'active', reason || null, id],
  );
  if (!result.affectedRows) throw new HttpError(404, 'Không tìm thấy tác giả.');
  const [rows] = await pool.execute(`${authorSelect} WHERE a.id = ?`, [id]);
  res.json({ success: true, data: mapAuthor(rows[0]) });
}

async function listReviews(req, res) {
  const status = text(req.query.status, 20);
  const search = text(req.query.search, 120);
  const filters = [];
  const params = [];
  if (status === 'visible' || status === 'locked') {
    filters.push('br.status = ?');
    params.push(status);
  }
  if (search) {
    filters.push('(br.comment LIKE ? OR b.title LIKE ? OR u.identifier LIKE ?)');
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }
  const where = filters.length ? ` WHERE ${filters.join(' AND ')}` : '';
  const [rows] = await pool.execute(
    `SELECT br.id, br.book_id AS bookId, b.title AS bookTitle,
      br.user_id AS userId, u.identifier, u.display_name AS displayName,
      br.rating, br.comment, br.is_anonymous AS isAnonymous,
      br.status, br.lock_reason AS lockReason,
      br.created_at AS createdAt, br.updated_at AS updatedAt
     FROM book_reviews br
     INNER JOIN books b ON b.id = br.book_id
     INNER JOIN users u ON u.id = br.user_id${where}
     ORDER BY br.id DESC LIMIT 300`,
    params,
  );
  res.json({
    success: true,
    data: rows.map((row) => ({ ...row, isAnonymous: Boolean(row.isAnonymous) })),
  });
}

async function lockReview(req, res) {
  const id = optionalId(req.params.id);
  if (!id) throw new HttpError(400, 'Mã bình luận không hợp lệ.');
  const locked = Boolean(req.body.locked);
  const reason = locked ? text(req.body.reason, 500) : '';
  if (locked && !reason) throw new HttpError(422, 'Vui lòng nhập lý do khóa bình luận.');
  const [result] = await pool.execute(
    `UPDATE book_reviews SET status = ?, lock_reason = ?, locked_by = ?,
      locked_at = ? WHERE id = ?`,
    [locked ? 'locked' : 'visible', reason || null, locked ? req.user.id : null,
      locked ? new Date() : null, id],
  );
  if (!result.affectedRows) throw new HttpError(404, 'Không tìm thấy bình luận.');
  res.json({ success: true, data: { id, status: locked ? 'locked' : 'visible' } });
}

module.exports = {
  dashboard,
  listBooks,
  createBook,
  updateBook,
  moderateBook,
  lockBook,
  submitAuthorApplication,
  myAuthorApplication,
  listAuthorApplications,
  reviewAuthorApplication,
  listAuthors,
  updateAuthor,
  lockAuthor,
  listReviews,
  lockReview,
  listOrders,
  updateOrderStatus,
  addShippingEvent,
  listPayments,
  updatePaymentStatus,
  listUsers,
  updateUser,
};
