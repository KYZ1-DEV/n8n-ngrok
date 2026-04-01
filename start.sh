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

# Counter mundur 25 detik
COUNT=25
while [ $COUNT -gt 0 ]; do
  echo "⏳ Aplikasi akan dijalankan dalam $COUNT detik..."
  sleep 1
  COUNT=$((COUNT-1))
done

echo "✅ DONE 🚀"

# Buka browser otomatis
xdg-open "$NGROK_URL" >/dev/null 2>&1 &
