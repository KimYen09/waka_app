const pool = require('../config/database');
const env = require('../config/env');
const HttpError = require('../utils/http-error');
const vnpay = require('../utils/vnpay');
const { applyPaymentStatus } = require('../services/payment-outcomes');

const checkoutVouchers = new Map([
  ['WAKA10', { percent: 10, minimumSubtotal: 100000 }],
  ['WAKA15', { percent: 15, minimumSubtotal: 250000 }],
]);

/// Link thanh toán VNPay hết hạn sau 15 phút; cho thêm biên độ trước khi coi
/// một giao dịch gói đang chờ là đã bị bỏ dở.
const PENDING_MEMBERSHIP_TIMEOUT_MS = 30 * 60 * 1000;

function cleanText(value, maxLength = 500) {
  return String(value || '').trim().slice(0, maxLength);
}

function ensureVnpayConfigured() {
  if (!env.vnpay.tmnCode || !env.vnpay.hashSecret) {
    throw new HttpError(
      422,
      'VNPay chưa được cấu hình. Hãy đặt VNP_TMN_CODE và VNP_HASH_SECRET cho backend.',
    );
  }
}

function clientIp(req) {
  const forwarded = String(req.headers['x-forwarded-for'] || '').split(',')[0].trim();
  const raw = forwarded || req.ip || req.socket?.remoteAddress || '127.0.0.1';
  const normalized = raw.replace('::ffff:', '');
  return normalized === '::1' ? '127.0.0.1' : normalized;
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function renderVnpayResultPage({ success, orderCode }) {
  const title = success ? 'Thanh toan thanh cong' : 'Thanh toan khong thanh cong';
  const message = success
    ? `Don hang ${escapeHtml(orderCode)} da duoc xac nhan. Ban co the dong cua so nay va quay lai ung dung Waka.`
    : `Giao dich cho don hang ${escapeHtml(orderCode)} khong thanh cong hoac da bi huy. Vui long quay lai ung dung Waka de thu lai.`;
  return `<!doctype html>
<html lang="vi"><head><meta charset="utf-8" />
<title>${title}</title>
<meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body style="font-family: sans-serif; text-align:center; padding: 48px 16px;">
  <h1>${success ? '✅' : '❌'} ${title}</h1>
  <p>${message}</p>
</body></html>`;
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
  const paymentMethod = ['bank_qr', 'vnpay'].includes(req.body.paymentMethod)
    ? req.body.paymentMethod
    : 'cod';
  if (paymentMethod === 'vnpay') ensureVnpayConfigured();
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
    const orderStatus = paymentMethod === 'bank_qr' || paymentMethod === 'vnpay'
      ? 'payment_review'
      : 'confirmed';
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
    const transactionRef = paymentMethod === 'cod'
      ? `COD-${Date.now()}-${orderResult.insertId}`
      : orderCode;
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
    const shippingEvent = paymentMethod === 'bank_qr'
      ? [
        orderResult.insertId,
        'payment_review',
        'Thanh toán trực tuyến',
        'Khách hàng đã báo chuyển khoản. Đang chờ quản trị viên xác nhận.',
      ]
      : paymentMethod === 'vnpay'
        ? [
          orderResult.insertId,
          'payment_review',
          'Thanh toán VNPay',
          'Đang chờ khách hàng hoàn tất thanh toán trên cổng VNPay.',
        ]
        : [
          orderResult.insertId,
          'confirmed',
          'Nhà sách Waka',
          'Đơn COD đã được tiếp nhận. Thanh toán khi giao hàng thành công.',
        ];
    await connection.execute(
      `INSERT INTO shipping_events
        (order_id, status, location, description, created_by)
       VALUES (?, ?, ?, ?, NULL)`,
      shippingEvent,
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
    const paymentUrl = paymentMethod === 'vnpay'
      ? vnpay.buildPaymentUrl({
        txnRef: transactionRef,
        amount: total,
        orderInfo: `Thanh toan don hang ${orderCode}`,
        ipAddr: clientIp(req),
      })
      : null;
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
        paymentUrl,
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
  const paymentMethod = req.body.paymentMethod === 'vnpay' ? 'vnpay' : 'bank_qr';
  if (paymentMethod === 'vnpay') {
    ensureVnpayConfigured();
  }
  const requestedTransactionRef = cleanText(req.body.transactionRef, 80);
  if (paymentMethod === 'bank_qr' && !requestedTransactionRef) {
    throw new HttpError(422, 'Thiếu nội dung chuyển khoản.');
  }
  const forceCancel = Boolean(req.body.forceCancel);
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

    // 1. Kiểm tra đơn pending của ĐÚNG user_id hiện tại với khoá FOR UPDATE
    const [pendingRows] = await connection.execute(
      `SELECT um.id, um.created_at AS createdAt, p.transaction_ref AS transactionRef,
              p.provider, p.amount, mp.title AS planTitle
       FROM user_memberships um
       LEFT JOIN payments p ON p.membership_id = um.id
       LEFT JOIN membership_plans mp ON mp.id = um.plan_id
       WHERE um.user_id = ? AND um.status = 'pending' FOR UPDATE`,
      [req.user.id],
    );

    const staleIds = [];
    const activePendingRows = [];

    for (const row of pendingRows) {
      if (!row || !row.id) continue;
      const createdAtTime = row.createdAt ? new Date(row.createdAt).getTime() : now.getTime();
      const isStale = (now.getTime() - createdAtTime) > PENDING_MEMBERSHIP_TIMEOUT_MS;
      if (isStale || forceCancel) {
        staleIds.push(row);
      } else {
        activePendingRows.push(row);
      }
    }

    // 2. Tự động hủy các đơn pending quá hạn (hoặc forceCancel) & ghi log Audit
    if (staleIds.length) {
      for (const item of staleIds) {
        if (!item || !item.id) continue;
        const reason = forceCancel ? 'user-requested-force-cancel' : 'auto-expired';
        console.log(
          `[AUDIT_LOG][MEMBERSHIP_CANCELLED] OrderId=${item.id}, UserId=${req.user.id}, TxnRef=${item.transactionRef || 'N/A'}, CancelledAt=${new Date().toISOString()}, Reason=${reason}`,
        );

        await connection.execute(
          `UPDATE user_memberships SET status = 'cancelled' WHERE id = ? AND user_id = ?`,
          [item.id, req.user.id],
        );
        await connection.execute(
          `UPDATE payments SET status = 'failed' WHERE membership_id = ? AND status IN ('pending', 'proof_submitted')`,
          [item.id],
        );
      }
    }

    // 3. Nếu còn đơn pending chưa quá hạn và KHÔNG có forceCancel: Trả về mã lỗi 409 PENDING_ORDER_EXISTS kèm link thanh toán cũ
    if (activePendingRows.length > 0 && !forceCancel) {
      await connection.rollback();
      const activePending = activePendingRows[0];
      const expiresAt = new Date(new Date(activePending.createdAt).getTime() + PENDING_MEMBERSHIP_TIMEOUT_MS);
      let existingPaymentUrl = null;

      if (activePending.provider === 'vnpay' && activePending.transactionRef) {
        existingPaymentUrl = vnpay.buildPaymentUrl({
          txnRef: activePending.transactionRef,
          amount: activePending.amount,
          orderInfo: `Thanh toan goi hoi vien ${activePending.planTitle || ''}`,
          ipAddr: clientIp(req),
        });
      }

      return res.status(409).json({
        success: false,
        code: 'PENDING_ORDER_EXISTS',
        message: 'Bạn đang có một giao dịch gói chưa hoàn tất. Vui lòng thanh toán tiếp hoặc chọn hủy để mua đơn mới.',
        data: {
          pendingId: activePending.id,
          paymentUrl: existingPaymentUrl,
          expiresAt: expiresAt.toISOString(),
          transactionRef: activePending.transactionRef,
        },
      });
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
    const transactionRef = paymentMethod === 'vnpay'
      ? `MB${membershipId}${Date.now()}`
      : requestedTransactionRef;
    const paymentStatus = paymentMethod === 'vnpay' ? 'pending' : 'proof_submitted';
    const [paymentResult] = await connection.execute(
      `INSERT INTO payments
        (user_id, membership_id, provider, transaction_ref, amount, status, paid_at)
       VALUES (?, ?, ?, ?, ?, ?, NULL)`,
      [req.user.id, membershipId, paymentMethod, transactionRef, plan.price, paymentStatus],
    );
    await connection.commit();
    const paymentUrl = paymentMethod === 'vnpay'
      ? vnpay.buildPaymentUrl({
        txnRef: transactionRef,
        amount: plan.price,
        orderInfo: `Thanh toan goi hoi vien ${plan.title}`,
        ipAddr: clientIp(req),
      })
      : null;
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
          status: paymentStatus,
        },
        paymentUrl,
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

/**
 * VNPay chuyển hướng trình duyệt (WebView) của khách về đây sau khi thanh
 * toán. Chỉ dùng để hiển thị trang kết quả cho người dùng — KHÔNG dùng để
 * xác nhận đơn hàng/gói hội viên, vì trình duyệt có thể đóng trước khi kịp
 * chuyển hướng. Nguồn xác nhận chính thức là vnpayIpn (VNPay gọi thẳng
 * server-to-server) bên dưới.
 */
async function vnpayReturn(req, res) {
  const query = { ...req.query };
  const success = vnpay.verifyReturn(query) && query.vnp_ResponseCode === '00';
  const orderCode = String(query.vnp_TxnRef || '');

  if (success && orderCode) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();
      const [rows] = await connection.execute(
        `SELECT id, amount, status FROM payments WHERE transaction_ref = ? LIMIT 1 FOR UPDATE`,
        [orderCode],
      );
      const payment = rows[0];
      if (payment && payment.status === 'pending') {
        await applyPaymentStatus(connection, {
          paymentId: payment.id,
          status: 'paid',
          actorUserId: null,
        });
      }
      await connection.commit();
    } catch (err) {
      await connection.rollback();
      console.error('[VNPay Return Activation Error]:', err);
    } finally {
      connection.release();
    }
  }

  res.set('Content-Type', 'text/html; charset=utf-8');
  res.send(renderVnpayResultPage({ success, orderCode }));
}

/**
 * Instant Payment Notification: VNPay gọi endpoint này trực tiếp từ server
 * của họ để xác nhận kết quả giao dịch. Phải luôn trả JSON theo đúng định
 * dạng RspCode/Message mà VNPay quy định, kể cả khi có lỗi nội bộ, để tránh
 * VNPay hiểu nhầm và retry vô tận.
 */
async function vnpayIpn(req, res) {
  try {
    const query = { ...req.query };
    if (!vnpay.verifyReturn(query)) {
      return res.json({ RspCode: '97', Message: 'Invalid signature' });
    }
    const transactionRef = String(query.vnp_TxnRef || '');
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();
      const [rows] = await connection.execute(
        `SELECT id, amount, status FROM payments WHERE transaction_ref = ? LIMIT 1 FOR UPDATE`,
        [transactionRef],
      );
      const payment = rows[0];
      if (!payment) {
        await connection.rollback();
        return res.json({ RspCode: '01', Message: 'Order not found' });
      }
      const vnpAmount = Math.round(Number(query.vnp_Amount || 0) / 100);
      if (vnpAmount !== Math.round(Number(payment.amount))) {
        await connection.rollback();
        return res.json({ RspCode: '04', Message: 'Invalid amount' });
      }
      if (payment.status !== 'pending') {
        await connection.rollback();
        return res.json({ RspCode: '02', Message: 'Order already confirmed' });
      }
      const success = query.vnp_ResponseCode === '00' && query.vnp_TransactionStatus === '00';
      await applyPaymentStatus(connection, {
        paymentId: payment.id,
        status: success ? 'paid' : 'failed',
        actorUserId: null,
      });
      await connection.commit();
      return res.json({ RspCode: '00', Message: 'Confirm Success' });
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  } catch (error) {
    console.error('[VNPay IPN Error]:', error);
    return res.json({ RspCode: '99', Message: 'Unknown error' });
  }
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
  vnpayReturn,
  vnpayIpn,
};
