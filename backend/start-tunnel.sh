#!/usr/bin/env bash
# ============================================================
# start-tunnel.sh
# Khởi động Cloudflare Tunnel, tự động cập nhật:
#   1. VNP_RETURN_URL trong backend/.env
#   2. API base URL trong Flutter api_endpoints.dart
#   3. Restart backend server
#
# Cách dùng: ./start-tunnel.sh
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/waka_cf_tunnel.log"
ENV_FILE="$SCRIPT_DIR/.env"
API_ENDPOINTS_FILE="$FLUTTER_DIR/lib/core/constants/api_endpoints.dart"

echo "🚀 Đang khởi động Cloudflare Tunnel..."

# Kill tunnel cũ nếu có
pkill -f "cloudflared tunnel" 2>/dev/null || true
sleep 1

# Khởi động tunnel nền, ghi log
cloudflared tunnel --url http://localhost:3000 > "$LOG_FILE" 2>&1 &
TUNNEL_PID=$!
echo "   Tunnel PID: $TUNNEL_PID"

# Chờ tối đa 25 giây để lấy URL
echo "⏳ Đợi Cloudflare cấp URL..."
TUNNEL_URL=""
for i in $(seq 1 25); do
  sleep 1
  TUNNEL_URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG_FILE" 2>/dev/null | head -1 || true)
  if [[ -n "$TUNNEL_URL" ]]; then
    break
  fi
done

if [[ -z "$TUNNEL_URL" ]]; then
  echo "❌ Không lấy được URL từ Cloudflare. Kiểm tra log: $LOG_FILE"
  exit 1
fi

echo "✅ Tunnel URL: $TUNNEL_URL"

# ── 1. Cập nhật VNP_RETURN_URL trong .env ──────────────────
RETURN_URL="${TUNNEL_URL}/api/payments/vnpay/return"
if grep -q "^VNP_RETURN_URL=" "$ENV_FILE"; then
  sed -i '' "s|^VNP_RETURN_URL=.*|VNP_RETURN_URL=${RETURN_URL}|" "$ENV_FILE"
else
  echo "VNP_RETURN_URL=${RETURN_URL}" >> "$ENV_FILE"
fi
echo "📝 .env  →  VNP_RETURN_URL=${RETURN_URL}"

# ── 2. Cập nhật api_endpoints.dart trong Flutter ───────────
if [[ -f "$API_ENDPOINTS_FILE" ]]; then
  # Thay dòng có trycloudflare.com/api bằng URL mới
  sed -i '' "s|https://[a-z0-9-]*\.trycloudflare\.com/api|${TUNNEL_URL}/api|g" "$API_ENDPOINTS_FILE"
  # Thay dòng có LAN IP (192.168.x.x:3000/api) nếu đang dùng IP
  sed -i '' "s|http://192\.[0-9.]*:3000/api|${TUNNEL_URL}/api|g" "$API_ENDPOINTS_FILE"
  # Thay dòng có 10.0.2.2 (emulator) nếu còn sót lại
  sed -i '' "s|http://10\.0\.2\.2:3000/api|${TUNNEL_URL}/api|g" "$API_ENDPOINTS_FILE"
  echo "📱 Flutter →  api_endpoints.dart đã cập nhật URL mới"
else
  echo "⚠️  Không tìm thấy api_endpoints.dart tại: $API_ENDPOINTS_FILE"
fi

# ── 3. Restart backend ──────────────────────────────────────
echo ""
echo "🔄 Restart backend server..."
pkill -f "node src/app.js" 2>/dev/null || true
sleep 1
cd "$SCRIPT_DIR"
node src/app.js > /tmp/waka_backend.log 2>&1 &
sleep 3

if curl -s http://localhost:3000/api/membership-plans > /dev/null 2>&1; then
  echo "✅ Backend đang chạy tại http://localhost:3000"
else
  echo "⚠️  Backend có thể chưa sẵn sàng. Xem log: /tmp/waka_backend.log"
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "  🌐 Tunnel URL : $TUNNEL_URL"
echo "  📦 Backend    : http://localhost:3000"
echo "  📱 Flutter    : đã cập nhật api_endpoints.dart"
echo "  💳 VNPay      : $RETURN_URL"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "👉 Bước tiếp theo: chạy 'flutter run' để build lại app"
echo "   (cần build lại vì api_endpoints.dart đã thay đổi)"
echo ""
echo "⚠️  Tunnel hết hạn sau vài giờ → chạy lại ./start-tunnel.sh"
echo "   Nhấn Ctrl+C để dừng tunnel và backend."
echo ""

# Đợi tunnel tắt
wait $TUNNEL_PID
