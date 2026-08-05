const fs = require('node:fs/promises');
const path = require('node:path');
const mysql = require('mysql2/promise');
const env = require('../src/config/env');

function slugify(value) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/đ/g, 'd')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

async function ensureColumn(connection, table, column, definition) {
  const [rows] = await connection.execute(
    `SELECT 1 FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
     LIMIT 1`,
    [table, column],
  );
  if (!rows.length) {
    await connection.query(`ALTER TABLE \`${table}\` ADD COLUMN \`${column}\` ${definition}`);
  }
}

async function init() {
  const connection = await mysql.createConnection({
    host: env.database.host,
    port: env.database.port,
    user: env.database.user,
    password: env.database.password,
    multipleStatements: true,
  });

  try {
    const schemaPath = path.join(__dirname, '../database/schema.sql');
    await connection.query(await fs.readFile(schemaPath, 'utf8'));
    await connection.changeUser({ database: env.database.database });

    await ensureColumn(
      connection,
      'users',
      'role',
      "ENUM('reader', 'author', 'admin') NOT NULL DEFAULT 'reader'",
    );
    await ensureColumn(
      connection,
      'users',
      'account_status',
      "ENUM('active', 'locked') NOT NULL DEFAULT 'active'",
    );
    await ensureColumn(connection, 'books', 'author_id', 'BIGINT UNSIGNED NULL');
    await ensureColumn(
      connection,
      'books',
      'moderation_status',
      "ENUM('draft', 'pending', 'approved', 'rejected') NOT NULL DEFAULT 'approved'",
    );
    await ensureColumn(connection, 'books', 'moderation_note', 'VARCHAR(500) NULL');
    await ensureColumn(
      connection,
      'books',
      'is_locked',
      'BOOLEAN NOT NULL DEFAULT FALSE',
    );
    await ensureColumn(connection, 'books', 'lock_reason', 'VARCHAR(500) NULL');
    await ensureColumn(connection, 'books', 'submitted_by', 'BIGINT UNSIGNED NULL');
    await ensureColumn(connection, 'books', 'reviewed_by', 'BIGINT UNSIGNED NULL');
    await ensureColumn(connection, 'books', 'reviewed_at', 'DATETIME NULL');
    await ensureColumn(connection, 'orders', 'order_code', 'VARCHAR(80) NULL');
    await ensureColumn(
      connection,
      'orders',
      'payment_method',
      "ENUM('cod', 'bank_qr', 'vnpay') NOT NULL DEFAULT 'cod'",
    );
    await ensureColumn(
      connection,
      'orders',
      'shipping_recipient',
      "VARCHAR(160) NOT NULL DEFAULT ''",
    );
    await ensureColumn(
      connection,
      'orders',
      'shipping_phone',
      "VARCHAR(30) NOT NULL DEFAULT ''",
    );
    await ensureColumn(connection, 'orders', 'shipping_address', 'TEXT NULL');
    await ensureColumn(
      connection,
      'orders',
      'updated_at',
      'TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
    );
    await connection.query(
      `ALTER TABLE orders MODIFY status ENUM(
        'pending', 'paid', 'payment_review', 'confirmed', 'packing',
        'in_transit', 'at_hub', 'out_for_delivery', 'delivered', 'cancelled'
       ) NOT NULL DEFAULT 'confirmed'`,
    );
    await connection.query(
      "UPDATE orders SET status = 'confirmed' WHERE status IN ('pending', 'paid')",
    );
    await connection.query(
      `ALTER TABLE orders MODIFY status ENUM(
        'payment_review', 'confirmed', 'packing', 'in_transit',
        'at_hub', 'out_for_delivery', 'delivered', 'cancelled'
       ) NOT NULL DEFAULT 'confirmed'`,
    );
    await connection.query(
      `ALTER TABLE orders MODIFY payment_method
       ENUM('cod', 'bank_qr', 'vnpay') NOT NULL DEFAULT 'cod'`,
    );
    await connection.query(
      `ALTER TABLE payments MODIFY status
       ENUM('pending', 'proof_submitted', 'paid', 'failed', 'refunded')
       NOT NULL DEFAULT 'pending'`,
    );
    await connection.query(
      `ALTER TABLE user_memberships MODIFY status
       ENUM('pending', 'active', 'expired', 'cancelled')
       NOT NULL DEFAULT 'pending'`,
    );

    if (env.adminIdentifiers.length) {
      const placeholders = env.adminIdentifiers.map(() => '?').join(',');
      await connection.execute(
        `UPDATE users u
         LEFT JOIN social_accounts sa ON sa.user_id = u.id
         SET u.role = 'admin', u.account_status = 'active'
         WHERE LOWER(u.identifier) IN (${placeholders})
            OR LOWER(sa.email) IN (${placeholders})`,
        [...env.adminIdentifiers, ...env.adminIdentifiers],
      );
    }

    const booksPath = path.join(__dirname, '../../assets/data/books.json');
    const source = JSON.parse(await fs.readFile(booksPath, 'utf8'));
    const discoveryPath = path.join(__dirname, '../../assets/data/discovery.json');
    const discovery = JSON.parse(await fs.readFile(discoveryPath, 'utf8'));
    const categoryIds = new Map();

    const categoryNames = new Set([
      ...(source.categories || []).map((category) => category.title),
      ...(source.books || []).map((book) => book.section),
    ]);
    for (const categoryName of categoryNames) {
      if (!categoryName) continue;
      const slug = slugify(categoryName);
      await connection.execute(
        `INSERT INTO categories (name, slug) VALUES (?, ?)
         ON DUPLICATE KEY UPDATE name = VALUES(name)`,
        [categoryName, slug],
      );
      const [rows] = await connection.execute(
        'SELECT id FROM categories WHERE slug = ? LIMIT 1',
        [slug],
      );
      categoryIds.set(categoryName, rows[0].id);
    }

    let index = 0;
    for (const book of source.books || []) {
      index += 1;
      const categoryId = categoryIds.get(book.section) || null;
      const price = 39000 + (index % 8) * 10000;
      const discount = [0, 10, 15, 20, 25][index % 5];
      await connection.execute(
        `INSERT INTO books
          (category_id, title, image_url, source_url, price, discount_percent, is_featured)
         SELECT ?, ?, ?, ?, ?, ?, ?
         WHERE NOT EXISTS (SELECT 1 FROM books WHERE title = ?)`,
        [
          categoryId,
          book.title,
          book.imageUrl || null,
          book.url || null,
          price,
          discount,
          index <= 10,
          book.title,
        ],
      );
    }

    await connection.query(
      `INSERT INTO offers (book_id, title, discount_percent, starts_at, ends_at)
       SELECT id, CONCAT('Ưu đãi ', title), GREATEST(discount_percent, 20), NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY)
       FROM books b
       WHERE b.discount_percent > 0
         AND NOT EXISTS (SELECT 1 FROM offers o WHERE o.book_id = b.id)
       ORDER BY b.id
       LIMIT 12`,
    );

    for (const ranking of discovery.rankings || []) {
      await connection.execute(
        `INSERT INTO rankings
          (book_id, period, content_type, rank_position, score, source_url)
         SELECT id, ?, ?, ?, ?, ? FROM books WHERE title = ? LIMIT 1
         ON DUPLICATE KEY UPDATE
          book_id = VALUES(book_id), score = VALUES(score),
          source_url = VALUES(source_url)`,
        [
          ranking.period || 'week',
          ranking.contentType || 'ebook',
          ranking.rank,
          ranking.score || 0,
          discovery.sources?.rankings || null,
          ranking.title,
        ],
      );
    }

    for (const recommendation of discovery.recommendations || []) {
      await connection.execute(
        `INSERT INTO recommendations
          (book_id, content_type, position, reason, source_url)
         SELECT id, ?, ?, ?, ? FROM books WHERE title = ? LIMIT 1
         ON DUPLICATE KEY UPDATE
          book_id = VALUES(book_id), reason = VALUES(reason),
          source_url = VALUES(source_url)`,
        [
          recommendation.contentType || 'ebook',
          recommendation.position,
          recommendation.reason || '',
          discovery.sources?.recommendations || null,
          recommendation.title,
        ],
      );
    }

    console.log(
      `Database initialized with ${(source.books || []).length} books, ` +
        `${(discovery.rankings || []).length} rankings and ` +
        `${(discovery.recommendations || []).length} recommendations.`,
    );
  } finally {
    await connection.end();
  }
}

init().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
