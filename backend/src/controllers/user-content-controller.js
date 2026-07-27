const pool = require('../config/database');
const HttpError = require('../utils/http-error');

async function listFavorites(req, res) {
  const [rows] = await pool.execute(
    `SELECT b.id, b.title, b.author, b.image_url AS imageUrl,
      b.price, b.discount_percent AS discountPercent,
      f.created_at AS createdAt
     FROM favorites f
     INNER JOIN books b ON b.id = f.book_id
     WHERE f.user_id = ?
     ORDER BY f.created_at DESC`,
    [req.user.id],
  );
  res.json({ success: true, data: rows });
}

async function addFavorite(req, res) {
  const bookId = Number.parseInt(req.body.bookId, 10);
  if (!Number.isInteger(bookId)) throw new HttpError(422, 'Mã sách không hợp lệ.');

  const [books] = await pool.execute('SELECT id FROM books WHERE id = ? LIMIT 1', [bookId]);
  if (!books.length) throw new HttpError(404, 'Không tìm thấy sách.');

  await pool.execute(
    'INSERT IGNORE INTO favorites (user_id, book_id) VALUES (?, ?)',
    [req.user.id, bookId],
  );
  res.status(201).json({ success: true, data: { bookId } });
}

async function removeFavorite(req, res) {
  const bookId = Number.parseInt(req.params.bookId, 10);
  if (!Number.isInteger(bookId)) throw new HttpError(400, 'Mã sách không hợp lệ.');

  await pool.execute('DELETE FROM favorites WHERE user_id = ? AND book_id = ?', [
    req.user.id,
    bookId,
  ]);
  res.status(204).end();
}

async function listOrders(req, res) {
  const [orders] = await pool.execute(
    `SELECT id, status, total, created_at AS createdAt
     FROM orders WHERE user_id = ? ORDER BY id DESC`,
    [req.user.id],
  );
  if (!orders.length) return res.json({ success: true, data: [] });

  const ids = orders.map((order) => order.id);
  const placeholders = ids.map(() => '?').join(',');
  const [items] = await pool.execute(
    `SELECT oi.order_id AS orderId, oi.book_id AS bookId, b.title,
      oi.quantity, oi.unit_price AS unitPrice
     FROM order_items oi
     INNER JOIN books b ON b.id = oi.book_id
     WHERE oi.order_id IN (${placeholders})`,
    ids,
  );
  const data = orders.map((order) => ({
    ...order,
    items: items.filter((item) => item.orderId === order.id),
  }));
  return res.json({ success: true, data });
}

async function createOrder(req, res) {
  const rawItems = Array.isArray(req.body.items) ? req.body.items : [];
  const quantities = new Map();
  for (const item of rawItems) {
    const bookId = Number.parseInt(item.bookId, 10);
    const quantity = Number.parseInt(item.quantity, 10) || 1;
    if (!Number.isInteger(bookId) || quantity < 1 || quantity > 99) {
      throw new HttpError(422, 'Danh sách sản phẩm không hợp lệ.');
    }
    quantities.set(bookId, (quantities.get(bookId) || 0) + quantity);
  }
  if (!quantities.size) throw new HttpError(422, 'Đơn hàng chưa có sản phẩm.');

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const bookIds = [...quantities.keys()];
    const placeholders = bookIds.map(() => '?').join(',');
    const [books] = await connection.execute(
      `SELECT id, price, discount_percent AS discountPercent
       FROM books WHERE id IN (${placeholders}) FOR UPDATE`,
      bookIds,
    );
    if (books.length !== bookIds.length) {
      throw new HttpError(422, 'Có sách trong đơn hàng không còn tồn tại.');
    }

    const prepared = books.map((book) => {
      const unitPrice = Number(book.price) * (1 - Number(book.discountPercent) / 100);
      return { bookId: book.id, quantity: quantities.get(book.id), unitPrice };
    });
    const total = prepared.reduce(
      (sum, item) => sum + item.unitPrice * item.quantity,
      0,
    );
    const [orderResult] = await connection.execute(
      'INSERT INTO orders (user_id, total) VALUES (?, ?)',
      [req.user.id, total],
    );
    for (const item of prepared) {
      await connection.execute(
        `INSERT INTO order_items (order_id, book_id, quantity, unit_price)
         VALUES (?, ?, ?, ?)`,
        [orderResult.insertId, item.bookId, item.quantity, item.unitPrice],
      );
    }
    await connection.commit();
    res.status(201).json({
      success: true,
      data: { id: orderResult.insertId, status: 'pending', total, items: prepared },
    });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

module.exports = {
  listFavorites,
  addFavorite,
  removeFavorite,
  listOrders,
  createOrder,
};
