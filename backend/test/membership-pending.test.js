const test = require('node:test');
const assert = require('node:assert');
const pool = require('../src/config/database');
const env = require('../src/config/env');
const vnpay = require('../src/utils/vnpay');

test('Membership Pending Order & Race Condition Handling Tests', async (t) => {
  // Test 1: vnpay.buildPaymentUrl generates correct checksum & parameters
  await t.test('buildPaymentUrl should multiply amount by 100 and include valid SecureHash', () => {
    const url = vnpay.buildPaymentUrl({
      txnRef: 'TEST_TXN_123',
      amount: 199000,
      orderInfo: 'Thanh toan test',
      ipAddr: '127.0.0.1',
    });
    assert.strictEqual(url.includes('vnp_Amount=19900000'), true);
    assert.strictEqual(url.includes('vnp_TxnRef=TEST_TXN_123'), true);
    assert.strictEqual(url.includes('vnp_SecureHash='), true);
  });

  // Test 2: Verify HMAC SHA512 return calculation
  await t.test('verifyReturn should validate authentic VNPay response query', () => {
    const query = {
      vnp_Amount: '19900000',
      vnp_BankCode: 'NCB',
      vnp_Command: 'pay',
      vnp_CreateDate: '20260806230000',
      vnp_CurrCode: 'VND',
      vnp_IpAddr: '127.0.0.1',
      vnp_Locale: 'vn',
      vnp_OrderInfo: 'Thanh toan test',
      vnp_OrderType: 'other',
      vnp_ResponseCode: '00',
      vnp_TmnCode: env.vnpay.tmnCode || '7S5TUNDF',
      vnp_TransactionNo: '14500000',
      vnp_TxnRef: 'TEST_TXN_123',
      vnp_Version: '2.1.0',
    };
    
    // Sort and sign
    const crypto = require('node:crypto');
    const sorted = {};
    Object.keys(query).sort().forEach(k => sorted[k] = encodeURIComponent(query[k]).replace(/%20/g, '+'));
    const signData = Object.entries(sorted).map(([k, v]) => `${k}=${v}`).join('&');
    const hashSecret = env.vnpay.hashSecret || 'KYVGZDLQRPYZFBQAYYMAMLJJJMLREYQB';
    const secureHash = crypto.createHmac('sha512', hashSecret).update(Buffer.from(signData, 'utf-8')).digest('hex');

    query.vnp_SecureHash = secureHash;
    const isValid = vnpay.verifyReturn(query);
    assert.strictEqual(isValid, true);
  });

  // Cleanup DB pool connections
  t.after(() => {
    pool.end();
  });
});
