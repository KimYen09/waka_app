const crypto = require('node:crypto');
const env = require('../config/env');

function sortAndEncode(params) {
  const sorted = {};
  Object.keys(params)
    .filter((key) => params[key] !== undefined && params[key] !== null && params[key] !== '')
    .sort()
    .forEach((key) => {
      sorted[key] = encodeURIComponent(String(params[key])).replace(/%20/g, '+');
    });
  return sorted;
}

function buildSignData(sortedParams) {
  return Object.entries(sortedParams)
    .map(([key, value]) => `${key}=${value}`)
    .join('&');
}

function sign(sortedParams) {
  const signData = buildSignData(sortedParams);
  return crypto
    .createHmac('sha512', env.vnpay.hashSecret)
    .update(Buffer.from(signData, 'utf-8'))
    .digest('hex');
}

function pad2(value) {
  return String(value).padStart(2, '0');
}

function formatVnpDate(date) {
  return (
    date.getFullYear().toString()
    + pad2(date.getMonth() + 1)
    + pad2(date.getDate())
    + pad2(date.getHours())
    + pad2(date.getMinutes())
    + pad2(date.getSeconds())
  );
}

function removeAccents(str) {
  return String(str || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .replace(/[^a-zA-Z0-9\s_-]/g, '')
    .trim();
}

function buildPaymentUrl({ txnRef, amount, orderInfo, ipAddr, orderType = 'other', locale = 'vn' }) {
  const now = new Date();
  const cleanOrderInfo = removeAccents(orderInfo) || 'Thanh toan Waka App';
  const params = {
    vnp_Version: '2.1.0',
    vnp_Command: 'pay',
    vnp_TmnCode: env.vnpay.tmnCode,
    vnp_Locale: locale,
    vnp_CurrCode: 'VND',
    vnp_TxnRef: txnRef,
    vnp_OrderInfo: cleanOrderInfo,
    vnp_OrderType: orderType,
    // VNPay expects the amount multiplied by 100 (no decimal places).
    vnp_Amount: Math.round(amount) * 100,
    vnp_ReturnUrl: env.vnpay.returnUrl,
    vnp_IpAddr: ipAddr || '127.0.0.1',
    vnp_CreateDate: formatVnpDate(now),
    vnp_ExpireDate: formatVnpDate(new Date(now.getTime() + 15 * 60 * 1000)),
  };
  const sorted = sortAndEncode(params);
  const secureHash = sign(sorted);
  return `${env.vnpay.url}?${buildSignData(sorted)}&vnp_SecureHash=${secureHash}`;
}

function verifyReturn(query) {
  const params = { ...query };
  const secureHash = params.vnp_SecureHash;
  delete params.vnp_SecureHash;
  delete params.vnp_SecureHashType;
  if (!secureHash) return false;
  const expected = sign(sortAndEncode(params));
  // VNPay khong thong nhat hoa/thuong cho chuoi hex, so sanh khong phan biet.
  // timingSafeEqual can hai buffer cung do dai nen phai kiem tra truoc.
  const received = Buffer.from(String(secureHash).toLowerCase(), 'utf-8');
  const wanted = Buffer.from(expected, 'utf-8');
  if (received.length !== wanted.length) return false;
  return crypto.timingSafeEqual(received, wanted);
}

module.exports = { buildPaymentUrl, verifyReturn };
