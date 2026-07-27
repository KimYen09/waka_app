const pool = require('../config/database');

async function listCategories(req, res) {
  const [rows] = await pool.query(
    `SELECT c.id, c.name, c.slug, COUNT(b.id) AS bookCount
     FROM categories c
     LEFT JOIN books b ON b.category_id = c.id
     GROUP BY c.id
     ORDER BY c.name`,
  );
  res.json({ success: true, data: rows });
}

async function listOffers(req, res) {
  const [rows] = await pool.query(
    `SELECT o.id, o.title, o.discount_percent AS discountPercent,
      o.starts_at AS startsAt, o.ends_at AS endsAt,
      b.id AS bookId, b.title AS bookTitle, b.author,
      b.image_url AS imageUrl, b.price
     FROM offers o
     INNER JOIN books b ON b.id = o.book_id
     WHERE (o.starts_at IS NULL OR o.starts_at <= NOW())
       AND (o.ends_at IS NULL OR o.ends_at >= NOW())
     ORDER BY o.discount_percent DESC, o.id DESC`,
  );
  res.json({ success: true, data: rows });
}

module.exports = { listCategories, listOffers };
