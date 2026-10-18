#!/bin/sh
# RevenueCat gizli anahtarını (sk_...) panodan okuyup prod API'nin ayar dosyasına yazar
# ve API container'ını bu ayarla yeniden oluşturur. Anahtar ekrana basılmaz.
# Kullanım: RevenueCat'te anahtarı kopyala, sonra: sh scripts/set-revenuecat-key.sh
set -eu

HOST=root@46.224.146.102
KEY=$(pbpaste | tr -d '[:space:]')

case "$KEY" in
  sk_*) ;;
  *) echo "Panoda sk_ ile başlayan bir anahtar yok. RevenueCat'ten gizli anahtarı kopyalayıp tekrar dene."; exit 1 ;;
esac
case "$KEY" in
  *[!A-Za-z0-9_]*) echo "Anahtarda beklenmeyen karakter var, yazılmadı."; exit 1 ;;
esac

printf '%s\n' "$KEY" | ssh "$HOST" 'set -eu
read -r K
F=/opt/somine/.env.runtime
cp "$F" "$F.bak-$(date +%Y%m%d%H%M%S)"
if grep -q "^RevenueCat__AppleApiKey=" "$F"; then
  sed -i "s|^RevenueCat__AppleApiKey=.*|RevenueCat__AppleApiKey=$K|" "$F"
else
  echo "RevenueCat__AppleApiKey=$K" >> "$F"
fi
IMAGE=$(docker inspect somine-api --format "{{.Config.Image}}")
docker rm -f somine-api >/dev/null
docker run -d --name somine-api --restart unless-stopped --network internet_agi -p 5181:8080 \
  --env-file "$F" -v /opt/somine/uploads:/app/uploads \
  -v /opt/somine/secrets/firebase-admin.json:/run/secrets/firebase-admin.json:ro "$IMAGE" >/dev/null
for i in $(seq 1 30); do
  c=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5181/health || true)
  [ "$c" = 200 ] && break
  sleep 2
done
echo "Anahtar yazıldı (sk_..., ${#K} karakter). API: $IMAGE, sağlık: $c"'
