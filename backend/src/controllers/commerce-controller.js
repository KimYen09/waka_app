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
  const title = success ? 'Thanh toán thành công!' : 'Thanh toán không thành công';
  const subtitle = success
    ? 'Gói hội viên Waka của bạn đã được kích hoạt'
    : 'Giao dịch bị hủy hoặc có lỗi xảy ra';
  const message = success
    ? `Mã đơn hàng <strong>${escapeHtml(orderCode)}</strong> đã được xác nhận. Bạn có thể đóng cửa sổ này và quay lại ứng dụng Waka để bắt đầu đọc sách.`
    : `Giao dịch cho đơn hàng <strong>${escapeHtml(orderCode)}</strong> không thành công hoặc đã bị hủy. Vui lòng quay lại ứng dụng Waka để thử lại.`;

  const accentColor = success ? '#1ED760' : '#FF4D4D';
  const accentGlow = success ? 'rgba(30,215,96,0.35)' : 'rgba(255,77,77,0.35)';
  const iconSvg = success
    ? `<svg viewBox="0 0 52 52" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="26" cy="26" r="25" stroke="${accentColor}" stroke-width="2"/>
        <path d="M14 27L22 35L38 18" stroke="${accentColor}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>
       </svg>`
    : `<svg viewBox="0 0 52 52" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="26" cy="26" r="25" stroke="${accentColor}" stroke-width="2"/>
        <path d="M18 18L34 34M34 18L18 34" stroke="${accentColor}" stroke-width="3.5" stroke-linecap="round"/>
       </svg>`;

  return `<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8" />
  <title>${title} – Waka</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet" />
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Inter', sans-serif;
      background: #0A0E1A;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      position: relative;
    }

    /* Ambient background blobs */
    .blob {
      position: fixed;
      border-radius: 50%;
      filter: blur(80px);
      opacity: 0.18;
      pointer-events: none;
      animation: float 8s ease-in-out infinite;
    }
    .blob-1 {
      width: 420px; height: 420px;
      background: ${accentColor};
      top: -120px; left: -100px;
      animation-delay: 0s;
    }
    .blob-2 {
      width: 300px; height: 300px;
      background: #7B61FF;
      bottom: -80px; right: -80px;
      animation-delay: -3s;
    }
    .blob-3 {
      width: 200px; height: 200px;
      background: ${accentColor};
      bottom: 100px; left: 60px;
      opacity: 0.08;
      animation-delay: -5s;
    }

    @keyframes float {
      0%, 100% { transform: translateY(0px) scale(1); }
      50% { transform: translateY(-24px) scale(1.04); }
    }

    /* Card */
    .card {
      position: relative;
      background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.09);
      border-radius: 28px;
      padding: 48px 36px 44px;
      max-width: 420px;
      width: calc(100% - 32px);
      text-align: center;
      backdrop-filter: blur(24px);
      -webkit-backdrop-filter: blur(24px);
      box-shadow: 0 32px 80px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.06);
      animation: cardIn 0.6s cubic-bezier(0.34,1.56,0.64,1) both;
    }

    @keyframes cardIn {
      from { opacity: 0; transform: scale(0.82) translateY(32px); }
      to   { opacity: 1; transform: scale(1) translateY(0); }
    }

    /* Logo */
    .logo {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      margin-bottom: 32px;
      opacity: 0;
      animation: fadeUp 0.5s 0.2s ease both;
    }
    .logo-dot {
      width: 10px; height: 10px;
      border-radius: 50%;
      background: ${accentColor};
      box-shadow: 0 0 12px ${accentColor};
    }
    .logo-text {
      font-size: 22px;
      font-weight: 900;
      color: #fff;
      letter-spacing: 3px;
      text-transform: uppercase;
    }

    /* Icon */
    .icon-wrap {
      width: 90px; height: 90px;
      margin: 0 auto 28px;
      position: relative;
      opacity: 0;
      animation: scaleIn 0.5s 0.35s cubic-bezier(0.34,1.56,0.64,1) both;
    }
    .icon-wrap svg {
      width: 100%;
      height: 100%;
      filter: drop-shadow(0 0 20px ${accentGlow});
    }
    .icon-ring {
      position: absolute;
      inset: -12px;
      border-radius: 50%;
      border: 2px solid ${accentColor};
      opacity: 0.2;
      animation: ringPulse 2s 1s ease infinite;
    }
    .icon-ring-2 {
      position: absolute;
      inset: -24px;
      border-radius: 50%;
      border: 1px solid ${accentColor};
      opacity: 0.1;
      animation: ringPulse 2s 1.3s ease infinite;
    }

    @keyframes ringPulse {
      0%, 100% { transform: scale(1); opacity: 0.15; }
      50% { transform: scale(1.08); opacity: 0.05; }
    }
    @keyframes scaleIn {
      from { opacity: 0; transform: scale(0.4); }
      to   { opacity: 1; transform: scale(1); }
    }

    /* Title */
    .title {
      font-size: 24px;
      font-weight: 800;
      color: #fff;
      line-height: 1.2;
      margin-bottom: 8px;
      opacity: 0;
      animation: fadeUp 0.4s 0.45s ease both;
    }
    .subtitle {
      font-size: 14px;
      font-weight: 500;
      color: ${accentColor};
      margin-bottom: 24px;
      letter-spacing: 0.3px;
      opacity: 0;
      animation: fadeUp 0.4s 0.5s ease both;
    }

    /* Divider */
    .divider {
      height: 1px;
      background: linear-gradient(to right, transparent, rgba(255,255,255,0.1), transparent);
      margin: 0 0 24px;
      opacity: 0;
      animation: fadeUp 0.4s 0.55s ease both;
    }

    /* Order info box */
    .order-box {
      background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.08);
      border-radius: 14px;
      padding: 16px 20px;
      margin-bottom: 24px;
      text-align: left;
      opacity: 0;
      animation: fadeUp 0.4s 0.6s ease both;
    }
    .order-label {
      font-size: 11px;
      font-weight: 600;
      color: rgba(255,255,255,0.35);
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 6px;
    }
    .order-code {
      font-size: 15px;
      font-weight: 700;
      color: rgba(255,255,255,0.9);
      font-family: 'SF Mono', 'Fira Code', monospace;
      letter-spacing: 0.5px;
    }

    /* Message */
    .message {
      font-size: 14px;
      line-height: 1.65;
      color: rgba(255,255,255,0.55);
      margin-bottom: 32px;
      opacity: 0;
      animation: fadeUp 0.4s 0.65s ease both;
    }
    .message strong { color: rgba(255,255,255,0.8); }

    /* Button */
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      width: 100%;
      padding: 15px 24px;
      border-radius: 14px;
      border: none;
      cursor: pointer;
      font-family: 'Inter', sans-serif;
      font-size: 15px;
      font-weight: 700;
      letter-spacing: 0.2px;
      text-decoration: none;
      transition: transform 0.15s ease, box-shadow 0.15s ease;
      opacity: 0;
      animation: fadeUp 0.4s 0.75s ease both;
    }
    .btn:active { transform: scale(0.97); }

    .btn-primary {
      background: linear-gradient(135deg, ${accentColor}, ${success ? '#17a84a' : '#c0392b'});
      color: ${success ? '#001a0d' : '#fff'};
      box-shadow: 0 8px 24px ${accentGlow};
    }
    .btn-primary:hover {
      box-shadow: 0 12px 32px ${accentGlow};
      transform: translateY(-1px);
    }

    /* Powered by VNPay badge */
    .powered {
      margin-top: 28px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      opacity: 0;
      animation: fadeUp 0.4s 0.85s ease both;
    }
    .powered span {
      font-size: 11px;
      color: rgba(255,255,255,0.2);
      font-weight: 500;
    }
    .powered strong {
      font-size: 11px;
      color: rgba(255,255,255,0.35);
      font-weight: 700;
      letter-spacing: 0.5px;
    }

    /* Confetti particles for success */
    .confetti-wrap {
      position: fixed; inset: 0;
      pointer-events: none;
      overflow: hidden;
    }
    .particle {
      position: absolute;
      top: -10px;
      width: 8px; height: 8px;
      border-radius: 2px;
      animation: fall linear infinite;
    }

    @keyframes fall {
      0%   { transform: translateY(-10px) rotate(0deg); opacity: 1; }
      85%  { opacity: 1; }
      100% { transform: translateY(110vh) rotate(720deg); opacity: 0; }
    }
    @keyframes fadeUp {
      from { opacity: 0; transform: translateY(16px); }
      to   { opacity: 1; transform: translateY(0); }
    }
  </style>
</head>
<body>

  <!-- Ambient blobs -->
  <div class="blob blob-1"></div>
  <div class="blob blob-2"></div>
  <div class="blob blob-3"></div>

  ${success ? `
  <!-- Confetti -->
  <div class="confetti-wrap" id="confetti"></div>
  ` : ''}

  <div class="card">
    <!-- Logo -->
    <div class="logo">
      <div class="logo-dot"></div>
      <span class="logo-text">Waka</span>
    </div>

    <!-- Icon -->
    <div class="icon-wrap">
      <div class="icon-ring"></div>
      <div class="icon-ring-2"></div>
      ${iconSvg}
    </div>

    <h1 class="title">${title}</h1>
    <p class="subtitle">${subtitle}</p>

    <div class="divider"></div>

    <div class="order-box">
      <div class="order-label">Mã giao dịch</div>
      <div class="order-code">${escapeHtml(orderCode) || '—'}</div>
    </div>

    <p class="message">${message}</p>

    <a href="javascript:window.close()" class="btn btn-primary">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="9 14 4 9 9 4"/><path d="M20 20v-7a4 4 0 0 0-4-4H4"/>
      </svg>
      Quay lại ứng dụng Waka
    </a>

    <div class="powered">
      <span>Thanh toán bảo mật bởi</span>
      <strong>VNPay</strong>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
      </svg>
    </div>
  </div>

  ${success ? `
  <script>
    // Confetti generator
    const wrap = document.getElementById('confetti');
    const colors = ['#1ED760','#7B61FF','#FFD25F','#FF6B6B','#4ECDC4','#45B7D1','#96CEB4'];
    for (let i = 0; i < 60; i++) {
      const el = document.createElement('div');
      el.className = 'particle';
      el.style.cssText = [
        'left:' + Math.random() * 100 + '%',
        'background:' + colors[Math.floor(Math.random() * colors.length)],
        'width:' + (Math.random() * 8 + 5) + 'px',
        'height:' + (Math.random() * 8 + 5) + 'px',
        'border-radius:' + (Math.random() > 0.5 ? '50%' : '2px'),
        'animation-duration:' + (Math.random() * 3 + 2.5) + 's',
        'animation-delay:' + (Math.random() * 3) + 's',
        'opacity:' + (Math.random() * 0.7 + 0.3),
      ].join(';');
      wrap.appendChild(el);
    }
  </script>
  ` : ''}
</body>
</html>`;
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
