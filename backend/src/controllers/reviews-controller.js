const pool = require('../config/database');
const HttpError = require('../utils/http-error');

function clean(value, max = 1500) {
  return String(value || '').trim().slice(0, max);
}

function bookIdOf(value) {
  const id = Number.parseInt(value, 10);
  if (!Number.isInteger(id) || id <= 0) throw new HttpError(400, 'Mã sách không hợp lệ.');
  return id;
}

function maskIdentifier(value) {
  const text = String(value || 'reader');
  const at = text.indexOf('@');
  const local = at >= 0 ? text.slice(0, at) : text;
  if (local.length <= 2) return 'Độc giả';
  return `${local.slice(0, 2)}${'*'.repeat(Math.min(10, local.length - 2))}`;
}

function mapReview(row, viewerId = null) {
  const anonymous = Boolean(row.isAnonymous);
  return {
    id: row.id,
    bookId: row.bookId,
    rating: Number(row.rating),
    comment: row.comment,
    isAnonymous: anonymous,
    displayName: anonymous ? 'Độc giả ẩn danh' : (row.displayName || maskIdentifier(row.identifier)),
    isMine: Number(row.userId) === Number(viewerId),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

async function listBookReviews(req, res) {
  const bookId = bookIdOf(req.params.bookId);
  const [summaryRows] = await pool.execute(
    `SELECT COUNT(*) AS reviewCount, COALESCE(AVG(rating), 0) AS averageRating
     FROM book_reviews WHERE book_id = ? AND status = 'visible'`,
    [bookId],
  );
  const [rows] = await pool.execute(
    `SELECT br.id, br.book_id AS bookId, br.user_id AS userId, br.rating,
      br.comment, br.is_anonymous AS isAnonymous, br.created_at AS createdAt,
      br.updated_at AS updatedAt, u.identifier, u.display_name AS displayName
     FROM book_reviews br INNER JOIN users u ON u.id = br.user_id
     WHERE br.book_id = ? AND br.status = 'visible'
     ORDER BY br.id DESC LIMIT 100`,
    [bookId],
  );
  const summary = summaryRows[0];
  res.json({
    success: true,
    data: {
      averageRating: Number(summary.averageRating || 0),
      reviewCount: Number(summary.reviewCount || 0),
      reviews: rows.map((row) => mapReview(row, req.user?.id)),
    },
  });
}

async function saveReview(req, res) {
  const bookId = bookIdOf(req.params.bookId);
  const rating = Number.parseInt(req.body.rating, 10);
  const comment = clean(req.body.comment);
  const isAnonymous = Boolean(req.body.isAnonymous);
  // Number.parseInt trả NaN khi thiếu/không phải số, mà mọi so sánh với NaN
  // đều false nên giá trị hỏng lọt qua và được lưu thành rating = 0, làm sai
  // cả điểm trung bình của sách.
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    throw new HttpError(422, 'Số sao phải từ 1 đến 5.');
  }
  if (comment.length < 3) throw new HttpError(422, 'Bình luận cần ít nhất 3 ký tự.');
  const [books] = await pool.execute('SELECT id FROM books WHERE id = ? LIMIT 1', [bookId]);
  if (!books.length) throw new HttpError(404, 'Không tìm thấy sách.');
  const [existing] = await pool.execute(
    'SELECT status FROM book_reviews WHERE user_id = ? AND book_id = ? LIMIT 1',
    [req.user.id, bookId],
  );
  if (existing[0]?.status === 'locked') {
    throw new HttpError(403, 'Đánh giá này đã bị admin khóa.');
  }
  await pool.execute(
    `INSERT INTO book_reviews (book_id, user_id, rating, comment, is_anonymous)
     VALUES (?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE rating = VALUES(rating), comment = VALUES(comment),
       is_anonymous = VALUES(is_anonymous), updated_at = CURRENT_TIMESTAMP`,
    [bookId, req.user.id, rating, comment, isAnonymous],
  );
  res.status(existing.length ? 200 : 201).json({ success: true });
}

module.exports = { listBookReviews, saveReview };
