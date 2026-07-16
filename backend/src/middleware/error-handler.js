function notFound(req, res) {
  res.status(404).json({
    success: false,
    message: `Không tìm thấy ${req.method} ${req.originalUrl}`,
  });
}

function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);

  const status = Number(error.status) || 500;
  const body = {
    success: false,
    message: status >= 500 ? 'Máy chủ đang gặp sự cố.' : error.message,
  };
  if (error.errors) body.errors = error.errors;
  if (process.env.NODE_ENV !== 'production' && status >= 500) {
    body.debug = error.message;
  }
  return res.status(status).json(body);
}

module.exports = { notFound, errorHandler };
