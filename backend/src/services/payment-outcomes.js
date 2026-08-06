/**
 * Áp dụng hệ quả nghiệp vụ khi trạng thái một giao dịch thanh toán thay đổi
 * (đơn hàng, gói hội viên, thông báo). Dùng chung cho luồng admin xác nhận
 * thủ công và luồng cổng thanh toán (VNPay IPN) xác nhận tự động, để tránh
 * hai nơi tự triển khai lại logic kích hoạt gói / xác nhận đơn rồi lệch nhau.
 */
async function applyPaymentStatus(connection, { paymentId, status, actorUserId = null }) {
  const [rows] = await connection.execute(
    `SELECT user_id AS userId, order_id AS orderId, membership_id AS membershipId,
      status AS previousStatus
     FROM payments WHERE id = ? LIMIT 1 FOR UPDATE`,
    [paymentId],
  );
  const payment = rows[0];
  if (!payment) return null;
  if (payment.previousStatus === status) return payment;

  await connection.execute(
    `UPDATE payments SET status = ?,
      paid_at = CASE WHEN ? = 'paid' THEN COALESCE(paid_at, NOW()) ELSE paid_at END
     WHERE id = ?`,
    [status, status, paymentId],
  );

  if (payment.orderId && status === 'paid') {
    await connection.execute(
      `UPDATE orders SET status = 'confirmed' WHERE id = ? AND status = 'payment_review'`,
      [payment.orderId],
    );
    await connection.execute(
      `INSERT INTO shipping_events
        (order_id, status, location, description, created_by)
       VALUES (?, 'confirmed', 'Nhà sách Waka',
        'Thanh toán đã được xác nhận. Đơn hàng bắt đầu được xử lý.', ?)`,
      [payment.orderId, actorUserId],
    );
  } else if (payment.orderId && (status === 'failed' || status === 'refunded')) {
    await connection.execute(`UPDATE orders SET status = 'cancelled' WHERE id = ?`, [payment.orderId]);
    await connection.execute(
      `INSERT INTO shipping_events
        (order_id, status, location, description, created_by)
       VALUES (?, 'cancelled', 'Nhà sách Waka', ?, ?)`,
      [
        payment.orderId,
        status === 'refunded'
          ? 'Giao dịch đã hoàn tiền và đơn hàng bị hủy.'
          : 'Thanh toán không thành công. Đơn hàng đã bị hủy.',
        actorUserId,
      ],
    );
  }

  if (payment.membershipId && (status === 'failed' || status === 'refunded')) {
    await connection.execute(
      `UPDATE user_memberships SET status = 'cancelled' WHERE id = ?`,
      [payment.membershipId],
    );
  }

  if (payment.membershipId && status === 'paid') {
    const [memberships] = await connection.execute(
      `SELECT um.id, um.user_id AS userId, um.status,
        mp.duration_days AS durationDays
       FROM user_memberships um
       INNER JOIN membership_plans mp ON mp.id = um.plan_id
       WHERE um.id = ? LIMIT 1 FOR UPDATE`,
      [payment.membershipId],
    );
    let membership = memberships[0];
    if (!membership && payment.userId) {
      const [userPending] = await connection.execute(
        `SELECT um.id, um.user_id AS userId, um.status,
          mp.duration_days AS durationDays
         FROM user_memberships um
         INNER JOIN membership_plans mp ON mp.id = um.plan_id
         WHERE um.user_id = ? AND um.status IN ('pending', 'cancelled')
         ORDER BY um.id DESC LIMIT 1 FOR UPDATE`,
        [payment.userId],
      );
      membership = userPending[0];
    }
    if (membership && membership.status !== 'active') {
      const [activeRows] = await connection.execute(
        `SELECT id, expires_at AS expiresAt FROM user_memberships
         WHERE user_id = ? AND status = 'active' AND expires_at > NOW()
         ORDER BY expires_at DESC LIMIT 1 FOR UPDATE`,
        [membership.userId],
      );
      const current = activeRows[0];
      const now = new Date();
      const base = current && new Date(current.expiresAt) > now
        ? new Date(current.expiresAt)
        : now;
      const expiresAt = new Date(base.getTime() + Number(membership.durationDays) * 86400000);
      if (current) {
        await connection.execute(
          `UPDATE user_memberships SET status = 'cancelled' WHERE id = ?`,
          [current.id],
        );
      }
      await connection.execute(
        `UPDATE user_memberships
         SET status = 'active', started_at = NOW(), expires_at = ?
         WHERE id = ?`,
        [expiresAt, membership.id],
      );
    }
  }

  if (payment.membershipId) {
    const notification = status === 'paid'
      ? {
        type: 'membership_approved',
        title: 'Gói Hội viên đã được kích hoạt',
        body: 'Thanh toán thành công. Bạn có thể đọc toàn bộ sách và chương Hội viên ngay bây giờ.',
      }
      : (status === 'failed' || status === 'refunded')
        ? {
          type: 'membership_rejected',
          title: 'Giao dịch gói chưa thành công',
          body: status === 'refunded'
            ? 'Giao dịch đã được chuyển sang trạng thái hoàn tiền.'
            : 'Thanh toán không thành công. Vui lòng kiểm tra và thử lại.',
        }
        : null;
    if (notification) {
      await connection.execute(
        `INSERT INTO notifications (user_id, type, title, body)
         VALUES (?, ?, ?, ?)`,
        [payment.userId, notification.type, notification.title, notification.body],
      );
    }
  }

  return payment;
}

module.exports = { applyPaymentStatus };
