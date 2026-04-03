#!/bin/bash

pkill ngrok

echo "🚀 Start ngrok (jika belum jalan)..."

if ! pgrep -x "ngrok" > /dev/null
then
    ngrok http 5678 > /dev/null &
fi

echo "⏳ Tunggu ngrok ready..."

for i in {1..6}
do
  NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o '"public_url":"[^"]*"' | cut -d '"' -f4)

  if [[ "$NGROK_URL" == https://* ]]; then
    echo "✅ Dapat URL: $NGROK_URL"
    break
  fi

  echo "⏳ Retry $i..."
  sleep 2
done

if [[ ! "$NGROK_URL" == https://* ]]; then
  echo "❌ Gagal ambil URL ngrok"
  exit 1
fi

echo "♻️ Restart n8n..."

export WEBHOOK_URL=$NGROK_URL

docker compose down
docker compose up -d

# Progress bar hijau
TOTAL=25
for ((i=0; i<=TOTAL; i++)); do
    PERCENT=$((i * 100 / TOTAL))
    FILLED=$((i * 30 / TOTAL))   # panjang bar = 30
    EMPTY=$((30 - FILLED))

    BAR=$(printf "%0.s█" $(seq 1 $FILLED))
    SPACE=$(printf "%0.s " $(seq 1 $EMPTY))

    # \r overwrite, \033[32m warna hijau, \033[0m reset
    printf "\r\033[32m⏳ [%s%s] %3d%%\033[0m" "$BAR" "$SPACE" "$PERCENT"

    sleep 1
done

printf "\r\033[32m✅ DONE 🚀                          \033[0m\n"

# Buka browser otomatis (WSL friendly)
if command -v wslview > /dev/null; then
    wslview "$NGROK_URL"
elif command -v xdg-open > /dev/null; then
    xdg-open "$NGROK_URL" >/dev/null 2>&1 &
else
    echo "⚠️ Tidak bisa membuka browser otomatis. Silakan buka manual:"
    echo "$NGROK_URL"
fi
