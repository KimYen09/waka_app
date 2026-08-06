const pool = require('../config/database');
const HttpError = require('../utils/http-error');

/**
 * Tự động tìm hoặc tạo bookId nếu nhận được bookId = 0 hoặc theo tiêu đề sách.
 */
async function resolveBookId(body) {
  let bookId = Number.parseInt(body.bookId, 10);
  if (Number.isInteger(bookId) && bookId > 0) {
    const [books] = await pool.execute('SELECT id FROM books WHERE id = ? LIMIT 1', [bookId]);
    if (books.length) return books[0].id;
  }

  const title = body.title ? String(body.title).trim() : '';
  if (title) {
    const [books] = await pool.execute('SELECT id FROM books WHERE title = ? LIMIT 1', [title]);
    if (books.length) return books[0].id;

    // Tự động thêm sách vào cơ sở dữ liệu nếu chưa tồn tại.
    //
    // Dữ liệu ở đây do client gửi lên nên phải vào hàng chờ kiểm duyệt:
    // `moderation_status` mặc định của bảng là 'approved', nếu không ghi đè
    // thì bất kỳ ai cũng đẩy được sách tự đặt tên lên catalog công khai.
    const [result] = await pool.execute(
      `INSERT INTO books
        (title, author, image_url, source_url, price, discount_percent,
         moderation_status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [
        title,
        body.author || 'Waka',
        body.imageUrl || null,
        body.sourceUrl || null,
        99000,
        0,
      ],
    );
    return result.insertId;
  }

  throw new HttpError(422, 'Mã sách hoặc tên sách không hợp lệ.');
}

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
  const bookId = await resolveBookId(req.body);

  await pool.execute(
    'INSERT IGNORE INTO favorites (user_id, book_id) VALUES (?, ?)',
    [req.user.id, bookId],
  );
  res.status(201).json({ success: true, data: { bookId } });
}

async function removeFavorite(req, res) {
  let bookId = Number.parseInt(req.params.bookId, 10);
  if (!Number.isInteger(bookId) || bookId <= 0) {
    const title = req.query.title ? String(req.query.title).trim() : '';
    if (title) {
      const [books] = await pool.execute('SELECT id FROM books WHERE title = ? LIMIT 1', [title]);
      if (books.length) bookId = books[0].id;
    }
  }

  if (Number.isInteger(bookId) && bookId > 0) {
    await pool.execute('DELETE FROM favorites WHERE user_id = ? AND book_id = ?', [
      req.user.id,
      bookId,
    ]);
  }
  res.status(204).end();
}

async function listOrders(req, res) {
  const [orders] = await pool.execute(
    `SELECT o.id, o.order_code AS orderCode, o.status, o.total,
      o.payment_method AS paymentMethod, p.status AS paymentStatus,
      o.shipping_recipient AS shippingRecipient,
      o.shipping_phone AS shippingPhone,
      o.shipping_address AS shippingAddress,
      o.created_at AS createdAt, o.updated_at AS updatedAt
     FROM orders o
     LEFT JOIN payments p ON p.order_id = o.id
     WHERE o.user_id = ? ORDER BY o.id DESC`,
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
  const [events] = await pool.execute(
    `SELECT id, order_id AS orderId, status, location, description,
      created_at AS createdAt
     FROM shipping_events
     WHERE order_id IN (${placeholders})
     ORDER BY created_at, id`,
    ids,
  );
  const data = orders.map((order) => ({
    ...order,
    items: items.filter((item) => item.orderId === order.id),
    shippingEvents: events.filter((event) => event.orderId === order.id),
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

async function upsertProgress(req, res) {
  const bookId = await resolveBookId(req.body);
  const currentPage = Number.parseInt(req.body.currentPage, 10);

  if (!Number.isInteger(currentPage) || currentPage < 0) {
    throw new HttpError(422, 'Số trang hiện tại không hợp lệ.');
  }

  await pool.execute(
    `INSERT INTO reading_progress (user_id, book_id, current_page)
     VALUES (?, ?, ?)
     ON DUPLICATE KEY UPDATE current_page = VALUES(current_page), updated_at = CURRENT_TIMESTAMP`,
    [req.user.id, bookId, currentPage],
  );

  res.status(200).json({
    success: true,
    data: { bookId, currentPage },
  });
}

async function getProgress(req, res) {
  let bookId = Number.parseInt(req.params.bookId, 10);
  if (!Number.isInteger(bookId) || bookId <= 0) {
    if (req.query.title) {
      const [books] = await pool.execute('SELECT id FROM books WHERE title = ? LIMIT 1', [req.query.title]);
      if (books.length) bookId = books[0].id;
    }
  }

  if (!Number.isInteger(bookId) || bookId <= 0) {
    return res.json({ success: true, data: null });
  }

  const [rows] = await pool.execute(
    `SELECT book_id AS bookId, current_page AS currentPage,
      updated_at AS updatedAt
     FROM reading_progress
     WHERE user_id = ? AND book_id = ?
     LIMIT 1`,
    [req.user.id, bookId],
  );

  if (!rows.length) {
    return res.json({ success: true, data: null });
  }

  res.json({ success: true, data: rows[0] });
}

async function listProgress(req, res) {
  const [rows] = await pool.execute(
    `SELECT rp.book_id AS bookId, rp.current_page AS currentPage,
      rp.updated_at AS updatedAt, b.title, b.author, b.image_url AS imageUrl,
      b.source_url AS sourceUrl
     FROM reading_progress rp
     INNER JOIN books b ON b.id = rp.book_id
     WHERE rp.user_id = ?
     ORDER BY rp.updated_at DESC`,
    [req.user.id],
  );

  res.json({ success: true, data: rows });
}

async function listDownloads(req, res) {
  const [rows] = await pool.execute(
    `SELECT b.id, b.title, b.author, b.image_url AS imageUrl,
      b.source_url AS sourceUrl, d.created_at AS downloadedAt
     FROM downloads d
     INNER JOIN books b ON b.id = d.book_id
     WHERE d.user_id = ?
     ORDER BY d.created_at DESC`,
    [req.user.id],
  );
  res.json({ success: true, data: rows });
}

async function addDownload(req, res) {
  const bookId = await resolveBookId(req.body);

  await pool.execute(
    'INSERT IGNORE INTO downloads (user_id, book_id) VALUES (?, ?)',
    [req.user.id, bookId],
  );
  res.status(201).json({ success: true, data: { bookId } });
}

async function removeDownload(req, res) {
  let bookId = Number.parseInt(req.params.bookId, 10);
  if (!Number.isInteger(bookId) || bookId <= 0) {
    const title = req.query.title ? String(req.query.title).trim() : '';
    if (title) {
      const [books] = await pool.execute('SELECT id FROM books WHERE title = ? LIMIT 1', [title]);
      if (books.length) bookId = books[0].id;
    }
  }

  if (Number.isInteger(bookId) && bookId > 0) {
    await pool.execute('DELETE FROM downloads WHERE user_id = ? AND book_id = ?', [
      req.user.id,
      bookId,
    ]);
  }
  res.status(204).end();
}

module.exports = {
  listFavorites,
  addFavorite,
  removeFavorite,
  listOrders,
  createOrder,
  upsertProgress,
  getProgress,
  listProgress,
  listDownloads,
  addDownload,
  removeDownload,
};
