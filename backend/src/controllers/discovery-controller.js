const pool = require('../config/database');

const discoveryBookFields = `
  b.id, b.title, b.author, b.description,
  b.image_url AS imageUrl, b.source_url AS sourceUrl,
  b.price, b.discount_percent AS discountPercent,
  b.is_featured AS isFeatured,
  c.id AS categoryId, c.name AS categoryName, c.slug AS categorySlug`;

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

async function listRankings(req, res) {
  const period = String(req.query.period || 'week').trim().toLowerCase();
  const contentType = String(req.query.contentType || 'ebook').trim().toLowerCase();
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 20, 1), 100);

  const [rows] = await pool.query(
    `SELECT ${discoveryBookFields},
      r.period, r.content_type AS contentType,
      r.rank_position AS rankPosition, r.score,
      r.source_url AS discoverySourceUrl, r.updated_at AS rankingUpdatedAt
     FROM rankings r
     INNER JOIN books b ON b.id = r.book_id
     LEFT JOIN categories c ON c.id = b.category_id
     WHERE r.period = ? AND r.content_type = ?
     ORDER BY r.rank_position
     LIMIT ?`,
    [period, contentType, limit],
  );

  res.json({
    success: true,
    data: rows.map((row) => ({
      rank: row.rankPosition,
      score: row.score,
      period: row.period,
      contentType: row.contentType,
      sourceUrl: row.discoverySourceUrl,
      updatedAt: row.rankingUpdatedAt,
      book: mapBook(row),
    })),
    meta: { period, contentType, count: rows.length },
  });
}

async function listRecommendations(req, res) {
  const contentType = String(req.query.contentType || 'ebook').trim().toLowerCase();
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 20, 1), 100);

  const [rows] = await pool.query(
    `SELECT ${discoveryBookFields},
      r.content_type AS contentType, r.position, r.reason,
      r.source_url AS discoverySourceUrl,
      r.updated_at AS recommendationUpdatedAt
     FROM recommendations r
     INNER JOIN books b ON b.id = r.book_id
     LEFT JOIN categories c ON c.id = b.category_id
     WHERE r.content_type = ?
     ORDER BY r.position
     LIMIT ?`,
    [contentType, limit],
  );

  res.json({
    success: true,
    data: rows.map((row) => ({
      position: row.position,
      reason: row.reason,
      contentType: row.contentType,
      sourceUrl: row.discoverySourceUrl,
      updatedAt: row.recommendationUpdatedAt,
      book: mapBook(row),
    })),
    meta: { contentType, count: rows.length },
  });
}

module.exports = { listRankings, listRecommendations };
