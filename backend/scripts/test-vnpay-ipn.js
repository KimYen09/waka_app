/**
 * Giả lập cú gọi IPN của VNPay để kiểm tra đường dây xác nhận thanh toán.
 *
 *   node scripts/test-vnpay-ipn.js <transactionRef> [amount] [baseUrl]
 *
 * - `transactionRef`: giá trị `transaction_ref` của một dòng trong bảng
 *   `payments` đang ở trạng thái `pending` (đơn/gói tạo bằng VNPay).
 * - `amount`: số tiền VND. Bỏ trống thì script tự đọc từ DB.
 * - `baseUrl`: gốc URL cần test. Bỏ trống thì suy ra từ `VNP_RETURN_URL`,
 *   tức là test đúng đường công khai mà VNPay sẽ dùng.
 *
 * Script ký query bằng `VNP_HASH_SECRET` y hệt VNPay, nên nếu nó nhận về
 * `RspCode 00` thì cú gọi thật của VNPay cũng sẽ chạy. Các mã khác:
 *   97 sai chữ ký · 01 không tìm thấy giao dịch · 04 lệch số tiền
 *   02 giao dịch đã được xử lý trước đó
 */
const crypto = require('node:crypto');
const env = require('../src/config/env');
const pool = require('../src/config/database');

function signQuery(params) {
  const sorted = {};
  Object.keys(params)
    .filter((key) => params[key] !== undefined && params[key] !== null && params[key] !== '')
    .sort()
    .forEach((key) => {
      sorted[key] = encodeURIComponent(String(params[key])).replace(/%20/g, '+');
    });
  const signData = Object.entries(sorted).map(([k, v]) => `${k}=${v}`).join('&');
  const hash = crypto
    .createHmac('sha512', env.vnpay.hashSecret)
    .update(Buffer.from(signData, 'utf-8'))
    .digest('hex');
  return { query: signData, hash };
}

function resolveBaseUrl(explicit) {
  if (explicit) return explicit.replace(/\/+$/, '');
  const returnUrl = env.vnpay.returnUrl || '';
  const marker = '/api/payments/vnpay/return';
  if (returnUrl.endsWith(marker)) return returnUrl.slice(0, -marker.length);
  throw new Error('Khong suy ra duoc baseUrl. Truyen tham so thu 3.');
}

async function main() {
  const [transactionRef, amountArg, baseUrlArg] = process.argv.slice(2);
  if (!transactionRef) {
    console.error('Thieu transactionRef. Vi du:\n  node scripts/test-vnpay-ipn.js WAKA1712345678');
    process.exitCode = 1;
    return;
  }

  let amount = Number(amountArg);
  if (!Number.isFinite(amount) || amount <= 0) {
    const [rows] = await pool.execute(
      'SELECT amount, status FROM payments WHERE transaction_ref = ? LIMIT 1',
      [transactionRef],
    );
    if (!rows.length) {
      console.error(`Khong tim thay payment nao co transaction_ref = ${transactionRef}`);
      process.exitCode = 1;
      return;
    }
    amount = Math.round(Number(rows[0].amount));
    console.log(`Doc tu DB: amount = ${amount} VND, status hien tai = ${rows[0].status}`);
    if (rows[0].status !== 'pending') {
      console.log('Luu y: chi trang thai "pending" moi duoc IPN xu ly, cac trang thai khac se tra RspCode 02.');
    }
  }

  const baseUrl = resolveBaseUrl(baseUrlArg);
  const params = {
    vnp_Amount: String(Math.round(amount) * 100),
    vnp_BankCode: 'NCB',
    vnp_CardType: 'ATM',
    vnp_OrderInfo: `Test IPN ${transactionRef}`,
    vnp_PayDate: new Date().toISOString().replace(/\D/g, '').slice(0, 14),
    vnp_ResponseCode: '00',
    vnp_TmnCode: env.vnpay.tmnCode,
    vnp_TransactionNo: '14000000',
    vnp_TransactionStatus: '00',
    vnp_TxnRef: transactionRef,
  };
  const { query, hash } = signQuery(params);
  const url = `${baseUrl}/api/payments/vnpay/ipn?${query}&vnp_SecureHash=${hash}`;

  console.log(`\nGoi IPN toi: ${baseUrl}/api/payments/vnpay/ipn`);
  const response = await fetch(url);
  const body = await response.text();
  console.log(`HTTP ${response.status}`);
  console.log(`Phan hoi: ${body}`);

  let parsed = null;
  try { parsed = JSON.parse(body); } catch { /* backend luon tra JSON, nhung khong tin tuyet doi */ }
  if (parsed && parsed.RspCode === '00') {
    console.log('\nKET LUAN: duong day IPN THONG. VNPay goi that se xac nhan duoc giao dich.');
  } else {
    console.log('\nKET LUAN: CHUA THONG. Xem bang ma o dau file de biet nguyen nhan.');
    process.exitCode = 1;
  }
}

main()
  .catch((error) => {
    console.error('Loi:', error.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
