const pool = require('../config/database');
const HttpError = require('../utils/http-error');

const checkoutVouchers = new Map([
  ['WAKA10', { percent: 10, minimumSubtotal: 100000 }],
  ['WAKA15', { percent: 15, minimumSubtotal: 250000 }],
]);

function cleanText(value, maxLength = 500) {
  return String(value || '').trim().slice(0, maxLength);
}

function mapPlan(row) {
  return {
    id: row.id,
    code: row.code,
    title: row.title,
    description: row.description,
    durationDays: row.durationDays,
    price: Number(row.price),
    listPrice: Number(row.listPrice),
    paymentChannel: row.paymentChannel,
    bonusDescription: row.bonusDescription,
  };
}

function mapCartItem(row) {
  return {
    bookId: row.bookId,
    quantity: row.quantity,
    title: row.title,
    author: row.author,
    imageUrl: row.imageUrl,
    sourceUrl: row.sourceUrl,
    price: Number(row.price),
    discountPercent: row.discountPercent,
    unitPrice: Number(row.unitPrice),
    lineTotal: Number(row.lineTotal),
  };
}

async function listCart(req, res) {
  const [rows] = await pool.execute(
    `SELECT ci.book_id AS bookId, ci.quantity, b.title, b.author,
      b.image_url AS imageUrl, b.source_url AS sourceUrl, b.price,
      b.discount_percent AS discountPercent,
      ROUND(b.price * (1 - b.discount_percent / 100), 2) AS unitPrice,
      ROUND(ci.quantity * b.price * (1 - b.discount_percent / 100), 2) AS lineTotal
     FROM cart_items ci
     INNER JOIN books b ON b.id = ci.book_id
     WHERE ci.user_id = ?
       AND b.moderation_status = 'approved' AND b.is_locked = FALSE
     ORDER BY ci.updated_at DESC`,
    [req.user.id],
  );
  const items = rows.map(mapCartItem);
  const total = items.reduce((sum, item) => sum + item.lineTotal, 0);
  res.json({ success: true, data: { items, total } });
}

async function upsertCartItem(req, res) {
  const bookId = Number.parseInt(req.body.bookId, 10);
  const quantity = Number.parseInt(req.body.quantity, 10);
  if (!Number.isInteger(bookId) || !Number.isInteger(quantity) || quantity < 1 || quantity > 99) {
    throw new HttpError(422, 'Sản phẩm hoặc số lượng không hợp lệ.');
  }
  const [books] = await pool.execute(
    `SELECT id FROM books
     WHERE id = ? AND moderation_status = 'approved' AND is_locked = FALSE
     LIMIT 1`,
    [bookId],
  );
  if (!books.length) throw new HttpError(404, 'Không tìm thấy sách.');
  await pool.execute(
    `INSERT INTO cart_items (user_id, book_id, quantity) VALUES (?, ?, ?)
     ON DUPLICATE KEY UPDATE quantity = VALUES(quantity)`,
    [req.user.id, bookId, quantity],
  );
  res.status(201).json({ success: true, data: { bookId, quantity } });
}

async function removeCartItem(req, res) {
  const bookId = Number.parseInt(req.params.bookId, 10);
  if (!Number.isInteger(bookId)) throw new HttpError(422, 'Mã sách không hợp lệ.');
  await pool.execute('DELETE FROM cart_items WHERE user_id = ? AND book_id = ?', [req.user.id, bookId]);
  res.status(204).end();
}

async function checkoutCart(req, res) {
  const voucherCode = typeof req.body.voucherCode === 'string'
    ? req.body.voucherCode.trim().toUpperCase()
    : '';
  const requestedBookIds = [...new Set(
    (Array.isArray(req.body.bookIds) ? req.body.bookIds : [])
      .map((value) => Number.parseInt(value, 10))
      .filter(Number.isInteger),
  )];
  const paymentMethod = req.body.paymentMethod === 'bank_qr' ? 'bank_qr' : 'cod';
  const requestedOrderCode = cleanText(req.body.orderCode, 80);
  const address = req.body.shippingAddress && typeof req.body.shippingAddress === 'object'
    ? req.body.shippingAddress
    : {};
  const recipient = cleanText(address.recipient, 160);
  const phone = cleanText(address.phone, 30);
  const fullAddress = [
    cleanText(address.streetAddress, 255),
    cleanText(address.ward, 160),
    cleanText(address.district, 160),
    cleanText(address.province, 160),
  ].filter(Boolean).join(', ');
  if (!recipient || !phone || !fullAddress) {
    throw new HttpError(422, 'Vui lòng cung cấp đầy đủ địa chỉ nhận hàng.');
  }
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const selection = requestedBookIds.length
      ? ` AND ci.book_id IN (${requestedBookIds.map(() => '?').join(',')})`
      : '';
    const [rows] = await connection.execute(
      `SELECT ci.book_id AS bookId, ci.quantity,
        ROUND(b.price * (1 - b.discount_percent / 100), 2) AS unitPrice
       FROM cart_items ci
       INNER JOIN books b ON b.id = ci.book_id
       WHERE ci.user_id = ?${selection}
         AND b.moderation_status = 'approved' AND b.is_locked = FALSE
       FOR UPDATE`,
      [req.user.id, ...requestedBookIds],
    );
    if (!rows.length) throw new HttpError(422, 'Giỏ hàng đang trống.');

    const subtotal = rows.reduce(
      (sum, item) => sum + Number(item.unitPrice) * item.quantity,
      0,
    );
    const voucher = voucherCode ? checkoutVouchers.get(voucherCode) : null;
    if (voucherCode && !voucher) {
      throw new HttpError(422, 'Voucher không hợp lệ.');
    }
    if (voucher && subtotal < voucher.minimumSubtotal) {
      throw new HttpError(422, 'Đơn hàng chưa đủ điều kiện áp dụng voucher.');
    }
    const discount = voucher
      ? Math.round(subtotal * voucher.percent / 100)
      : 0;
    const total = Math.max(0, subtotal - discount);
    const orderStatus = paymentMethod === 'bank_qr' ? 'payment_review' : 'confirmed';
    const orderCode = requestedOrderCode || `WAKA${Date.now()}`;
    const [orderResult] = await connection.execute(
      `INSERT INTO orders
        (user_id, order_code, payment_method, status, total,
         shipping_recipient, shipping_phone, shipping_address)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        orderCode,
        paymentMethod,
        orderStatus,
        total,
        recipient,
        phone,
        fullAddress,
      ],
    );
    for (const item of rows) {
      await connection.execute(
        `INSERT INTO order_items (order_id, book_id, quantity, unit_price)
         VALUES (?, ?, ?, ?)`,
        [orderResult.insertId, item.bookId, item.quantity, item.unitPrice],
      );
    }
    const transactionRef = paymentMethod === 'bank_qr'
      ? orderCode
      : `COD-${Date.now()}-${orderResult.insertId}`;
    const paymentStatus = paymentMethod === 'bank_qr' ? 'proof_submitted' : 'pending';
    const [paymentResult] = await connection.execute(
      `INSERT INTO payments
        (user_id, order_id, provider, transaction_ref, amount, status, paid_at)
       VALUES (?, ?, ?, ?, ?, ?, NULL)`,
      [
        req.user.id,
        orderResult.insertId,
        paymentMethod,
        transactionRef,
        total,
        paymentStatus,
      ],
    );
    await connection.execute(
      `INSERT INTO shipping_events
        (order_id, status, location, description, created_by)
       VALUES (?, ?, ?, ?, NULL)`,
      paymentMethod === 'bank_qr'
        ? [
          orderResult.insertId,
          'payment_review',
          'Thanh toán trực tuyến',
          'Khách hàng đã báo chuyển khoản. Đang chờ quản trị viên xác nhận.',
        ]
        : [
          orderResult.insertId,
          'confirmed',
          'Nhà sách Waka',
          'Đơn COD đã được tiếp nhận. Thanh toán khi giao hàng thành công.',
        ],
    );
    if (requestedBookIds.length) {
      await connection.execute(
        `DELETE FROM cart_items WHERE user_id = ?
         AND book_id IN (${requestedBookIds.map(() => '?').join(',')})`,
        [req.user.id, ...requestedBookIds],
      );
    } else {
      await connection.execute('DELETE FROM cart_items WHERE user_id = ?', [req.user.id]);
    }
    await connection.commit();
    res.status(201).json({
      success: true,
      data: {
        orderId: orderResult.insertId,
        orderCode,
        paymentMethod,
        status: orderStatus,
        subtotal,
        discount,
        voucherCode: voucherCode || null,
        total,
        payment: {
          id: paymentResult.insertId,
          transactionRef,
          status: paymentStatus,
        },
      },
    });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

async function listMembershipPlans(req, res) {
  const [rows] = await pool.execute(
    `SELECT id, code, title, description, duration_days AS durationDays,
      price, list_price AS listPrice, payment_channel AS paymentChannel,
      bonus_description AS bonusDescription
     FROM membership_plans WHERE is_active = TRUE ORDER BY sort_order, id`,
  );
  res.json({ success: true, data: rows.map(mapPlan) });
}

async function listMyMemberships(req, res) {
  await pool.execute(
    `UPDATE user_memberships SET status = 'expired'
     WHERE user_id = ? AND status = 'active' AND expires_at <= NOW()`,
    [req.user.id],
  );
  const [rows] = await pool.execute(
    `SELECT um.id, um.status, um.started_at AS startedAt, um.expires_at AS expiresAt,
      mp.id AS planId, mp.title AS planTitle, mp.duration_days AS durationDays,
      mp.price, mp.payment_channel AS paymentChannel, p.transaction_ref AS transactionRef
     FROM user_memberships um
     INNER JOIN membership_plans mp ON mp.id = um.plan_id
     LEFT JOIN payments p ON p.membership_id = um.id
     WHERE um.user_id = ? ORDER BY um.id DESC`,
    [req.user.id],
  );
  res.json({ success: true, data: rows });
}

async function purchaseMembership(req, res) {
  const planId = Number.parseInt(req.body.planId, 10);
  if (!Number.isInteger(planId)) throw new HttpError(422, 'Gói cước không hợp lệ.');
  const requestedTransactionRef = cleanText(req.body.transactionRef, 80);
  if (!requestedTransactionRef) throw new HttpError(422, 'Thiếu nội dung chuyển khoản.');
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [plans] = await connection.execute(
      `SELECT id, title, duration_days AS durationDays, price
       FROM membership_plans WHERE id = ? AND is_active = TRUE LIMIT 1 FOR UPDATE`,
      [planId],
    );
    const plan = plans[0];
    if (!plan) throw new HttpError(404, 'Gói cước không còn hiệu lực.');
    const now = new Date();
    const [pendingRows] = await connection.execute(
      `SELECT id FROM user_memberships
       WHERE user_id = ? AND status = 'pending' LIMIT 1 FOR UPDATE`,
      [req.user.id],
    );
    if (pendingRows.length) {
      throw new HttpError(409, 'Bạn đang có một giao dịch gói chờ quản trị viên duyệt.');
    }
    const [activeRows] = await connection.execute(
      `SELECT um.id, um.started_at AS startedAt, um.expires_at AS expiresAt,
        mp.price, mp.title
       FROM user_memberships um
       INNER JOIN membership_plans mp ON mp.id = um.plan_id
       WHERE um.user_id = ? AND um.status = 'active' AND um.expires_at > NOW()
       ORDER BY um.expires_at DESC LIMIT 1 FOR UPDATE`,
      [req.user.id],
    );
    const current = activeRows[0];
    if (current && Number(plan.price) < Number(current.price)) {
      throw new HttpError(
        422,
        `Bạn đang dùng ${current.title}. Chỉ có thể gia hạn hoặc nâng cấp gói.`,
      );
    }
    const [membershipResult] = await connection.execute(
      `INSERT INTO user_memberships (user_id, plan_id, status, started_at, expires_at)
       VALUES (?, ?, 'pending', ?, ?)`,
      [req.user.id, plan.id, now, now],
    );
    const membershipId = membershipResult.insertId;
    const startedAt = now;
    const expiresAt = now;
    const transactionRef = requestedTransactionRef;
    const [paymentResult] = await connection.execute(
      `INSERT INTO payments
        (user_id, membership_id, provider, transaction_ref, amount, status, paid_at)
       VALUES (?, ?, 'bank_qr', ?, ?, 'proof_submitted', NULL)`,
      [req.user.id, membershipId, transactionRef, plan.price],
    );
    await connection.commit();
    res.status(201).json({
      success: true,
      data: {
        membershipId,
        planId: plan.id,
        planTitle: plan.title,
        price: Number(plan.price),
        status: 'pending',
        startedAt,
        expiresAt,
        payment: {
          id: paymentResult.insertId,
          transactionRef,
          status: 'proof_submitted',
        },
      },
    });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

async function cancelMembership(req, res) {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [memberships] = await connection.execute(
      `SELECT id FROM user_memberships
       WHERE user_id = ? AND status IN ('active', 'pending') FOR UPDATE`,
      [req.user.id],
    );
    if (!memberships.length) {
      throw new HttpError(404, 'Bạn không có đăng ký nào để hủy.');
    }
    const ids = memberships.map((item) => item.id);
    const placeholders = ids.map(() => '?').join(',');
    await connection.execute(
      `UPDATE user_memberships SET status = 'cancelled'
       WHERE id IN (${placeholders})`,
      ids,
    );
    await connection.execute(
      `UPDATE payments SET status = 'failed'
       WHERE membership_id IN (${placeholders})
         AND status IN ('pending', 'proof_submitted')`,
      ids,
    );
    await connection.commit();
    res.json({ success: true, data: { cancelled: ids.length } });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

async function listPayments(req, res) {
  const [rows] = await pool.execute(
    `SELECT id, order_id AS orderId, membership_id AS membershipId, provider,
      transaction_ref AS transactionRef, amount, status, paid_at AS paidAt,
      created_at AS createdAt
     FROM payments WHERE user_id = ? ORDER BY id DESC`,
    [req.user.id],
  );
  res.json({ success: true, data: rows });
}

async function listNotifications(req, res) {
  const [rows] = await pool.execute(
    `SELECT id, type, title, body, is_read AS isRead, created_at AS createdAt
     FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT 100`,
    [req.user.id],
  );
  res.json({
    success: true,
    data: rows.map((item) => ({ ...item, isRead: Boolean(item.isRead) })),
  });
}

async function markNotificationRead(req, res) {
  const id = Number.parseInt(req.params.id, 10);
  if (!Number.isInteger(id)) throw new HttpError(400, 'Mã thông báo không hợp lệ.');
  await pool.execute(
    'UPDATE notifications SET is_read = TRUE WHERE id = ? AND user_id = ?',
    [id, req.user.id],
  );
  res.json({ success: true, data: { id, isRead: true } });
}

module.exports = {
  listCart,
  upsertCartItem,
  removeCartItem,
  checkoutCart,
  listMembershipPlans,
  listMyMemberships,
  purchaseMembership,
  cancelMembership,
  listPayments,
  listNotifications,
  markNotificationRead,
};
