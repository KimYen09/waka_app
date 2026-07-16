const pool = require('../config/database');
const HttpError = require('../utils/http-error');

const bookSelect = `
  SELECT b.id, b.title, b.author, b.description,
    b.image_url AS imageUrl, b.source_url AS sourceUrl,
    b.price, b.discount_percent AS discountPercent,
    b.is_featured AS isFeatured,
    c.id AS categoryId, c.name AS categoryName, c.slug AS categorySlug
  FROM books b
  LEFT JOIN categories c ON c.id = b.category_id`;

function mapBook(row) {
  return {
    id: row.id,
    title: row.title,
    author: row.author,
    description: row.description,
    imageUrl: row.imageUrl,
    sourceUrl: row.sourceUrl,
    price: row.price,
    discountPercent: row.discountPercent,
    isFeatured: Boolean(row.isFeatured),
    category: row.categoryId
      ? { id: row.categoryId, name: row.categoryName, slug: row.categorySlug }
      : null,
  };
}

async function listBooks(req, res) {
  const page = Math.max(Number.parseInt(req.query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 20, 1), 100);
  const offset = (page - 1) * limit;
  const search = String(req.query.search || '').trim();
  const categoryId = Number.parseInt(req.query.categoryId, 10);

  const filters = [];
  const params = [];
  if (search) {
    filters.push('(b.title LIKE ? OR b.author LIKE ?)');
    params.push(`%${search}%`, `%${search}%`);
  }
  if (Number.isInteger(categoryId) && categoryId > 0) {
    filters.push('b.category_id = ?');
    params.push(categoryId);
  }
  const where = filters.length ? ` WHERE ${filters.join(' AND ')}` : '';

  const [countRows] = await pool.execute(
    `SELECT COUNT(*) AS total FROM books b${where}`,
    params,
  );
  const [rows] = await pool.query(
    `${bookSelect}${where} ORDER BY b.is_featured DESC, b.id DESC LIMIT ? OFFSET ?`,
    [...params, limit, offset],
  );
  const total = Number(countRows[0].total);

  res.json({
    success: true,
    data: rows.map(mapBook),
    meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
  });
}

async function getBook(req, res) {
  const id = Number.parseInt(req.params.id, 10);
  if (!Number.isInteger(id)) throw new HttpError(400, 'Mã sách không hợp lệ.');

  const [rows] = await pool.execute(`${bookSelect} WHERE b.id = ? LIMIT 1`, [id]);
  if (!rows.length) throw new HttpError(404, 'Không tìm thấy sách.');
  res.json({ success: true, data: mapBook(rows[0]) });
}

module.exports = { listBooks, getBook };
