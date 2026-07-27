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
