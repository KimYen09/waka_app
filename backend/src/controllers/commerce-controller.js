const pool = require('../config/database');
const HttpError = require('../utils/http-error');

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
  const [books] = await pool.execute('SELECT id FROM books WHERE id = ? LIMIT 1', [bookId]);
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
  const requestedBookIds = [...new Set(
    (Array.isArray(req.body.bookIds) ? req.body.bookIds : [])
      .map((value) => Number.parseInt(value, 10))
      .filter(Number.isInteger),
  )];
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
       WHERE ci.user_id = ?${selection} FOR UPDATE`,
      [req.user.id, ...requestedBookIds],
    );
    if (!rows.length) throw new HttpError(422, 'Giỏ hàng đang trống.');

    const total = rows.reduce((sum, item) => sum + Number(item.unitPrice) * item.quantity, 0);
    const [orderResult] = await connection.execute(
      'INSERT INTO orders (user_id, status, total) VALUES (?, ?, ?)',
      [req.user.id, 'paid', total],
    );
    for (const item of rows) {
      await connection.execute(
        `INSERT INTO order_items (order_id, book_id, quantity, unit_price)
         VALUES (?, ?, ?, ?)`,
        [orderResult.insertId, item.bookId, item.quantity, item.unitPrice],
      );
    }
    const transactionRef = `DEMO-ORDER-${Date.now()}-${orderResult.insertId}`;
    const [paymentResult] = await connection.execute(
      `INSERT INTO payments
        (user_id, order_id, provider, transaction_ref, amount, status, paid_at)
       VALUES (?, ?, 'demo', ?, ?, 'paid', NOW())`,
      [req.user.id, orderResult.insertId, transactionRef, total],
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
        status: 'paid',
        total,
        payment: { id: paymentResult.insertId, transactionRef, status: 'paid' },
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
    const startedAt = new Date();
    const expiresAt = new Date(startedAt.getTime() + Number(plan.durationDays) * 86400000);
    const [membershipResult] = await connection.execute(
      `INSERT INTO user_memberships (user_id, plan_id, status, started_at, expires_at)
       VALUES (?, ?, 'active', ?, ?)`,
      [req.user.id, plan.id, startedAt, expiresAt],
    );
    const transactionRef = `DEMO-PLAN-${Date.now()}-${membershipResult.insertId}`;
    const [paymentResult] = await connection.execute(
      `INSERT INTO payments
        (user_id, membership_id, provider, transaction_ref, amount, status, paid_at)
       VALUES (?, ?, 'demo', ?, ?, 'paid', NOW())`,
      [req.user.id, membershipResult.insertId, transactionRef, plan.price],
    );
    await connection.commit();
    res.status(201).json({
      success: true,
      data: {
        membershipId: membershipResult.insertId,
        planTitle: plan.title,
        status: 'active',
        startedAt,
        expiresAt,
        payment: { id: paymentResult.insertId, transactionRef, status: 'paid' },
      },
    });
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

module.exports = {
  listCart,
  upsertCartItem,
  removeCartItem,
  checkoutCart,
  listMembershipPlans,
  listMyMemberships,
  purchaseMembership,
  listPayments,
};
