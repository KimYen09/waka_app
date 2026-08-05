/**
 * Liet ke cac giao dich VNPay trong DB de lay `transaction_ref` truyen cho
 * scripts/test-vnpay-ipn.js.
 *
 *   node scripts/list-vnpay-payments.js
 *
 * Chi giao dich o trang thai `pending` moi duoc IPN xu ly — cac trang thai
 * khac se nhan RspCode 02 (da xu ly truoc do).
 */
const pool = require('../src/config/database');

async function main() {
  const [rows] = await pool.execute(
    `SELECT p.transaction_ref AS ref, p.amount, p.status,
            p.order_id AS orderId, p.membership_id AS membershipId,
            p.created_at AS createdAt
     FROM payments p
     WHERE p.provider = 'vnpay'
     ORDER BY p.id DESC
     LIMIT 20`,
  );

  if (!rows.length) {
    console.log('Chua co giao dich VNPay nao.');
    console.log('Tao mot cai tu app: man Goi hoi vien -> chon goi -> "Cong VNPay".');
    return;
  }

  console.log('transaction_ref            | tien      | status   | thuoc ve');
  console.log('---------------------------|-----------|----------|---------------');
  for (const row of rows) {
    const target = row.orderId
      ? `don #${row.orderId}`
      : row.membershipId ? `goi #${row.membershipId}` : '-';
    console.log(
      `${String(row.ref).padEnd(26)} | ${String(Math.round(row.amount)).padEnd(9)} `
      + `| ${String(row.status).padEnd(8)} | ${target}`,
    );
  }

  const pending = rows.filter((row) => row.status === 'pending');
  if (pending.length) {
    console.log(`\nChay thu IPN voi giao dich dang cho:\n  node scripts/test-vnpay-ipn.js ${pending[0].ref}`);
  } else {
    console.log('\nKhong co giao dich nao dang "pending". Tao moi tu app roi chay lai.');
  }
}

main()
  .catch((error) => {
    console.error('Loi:', error.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
