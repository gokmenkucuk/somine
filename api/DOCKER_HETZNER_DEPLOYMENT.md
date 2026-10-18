# SoMine API Docker Deployment

Bu kurulum tek Hetzner sunucuda `docker compose` ile API ve PostgreSQL'i ayağa kaldırır.

İki model vardır:

- `docker-compose.yml`: kaynak kod sunucudayken sunucuda build eder
- `docker-compose.server.yml`: image lokalde build edilip sunucuya taşınır

Önerilen model: `docker-compose.server.yml`

## 1. Sunucuda klasörleri oluştur

```bash
mkdir -p /opt/somine
mkdir -p /opt/somine/uploads
mkdir -p /opt/somine/secrets
cd /opt/somine
```

## 2. Sunucuda `.env` dosyasını oluştur

Sunucuda `.env.production.example` dosyasını `.env` olarak kopyala:

```bash
cp .env.production.example .env
```

## 3. `.env` dosyasını düzenle

```bash
nano /opt/somine/.env
```

Canlıya çıkmadan önce özellikle şu alanları doldur:

- `POSTGRES_PASSWORD`
- `ConnectionStrings__PostgreSQL`
- `Jwt__Secret`
- `Jwt__Issuer`
- `RevenueCat__AppleApiKey`
- `RevenueCat__GoogleApiKey`
- `RevenueCat__ProjectId`
- `Storage__BaseUrl`

Not:

- Sadece IP ile test edeceksen `Jwt__Issuer` ve `Storage__BaseUrl` IP tabanlı olabilir.
- Mobil istemci imzalı client proof üretmiyorsa `ClientRequestSecurity__Enabled=false` kalmalı.
- Şikâyet e-postaları için `Moderation__ReportEmail` ve `Moderation__Smtp__*` doldurulmalı. Boşsa şikâyetler yalnızca `content_reports` tablosuna düşer, kimseye haber gitmez.
- GSO Studio yönetim paneli için `Admin__ApiKey` (en az 32 karakter rastgele, ör. `openssl rand -hex 32`). Boşsa `/api/admin/*` uçları 404 döner. Panel aynı değeri `SOMINE_ADMIN_KEY` env'i ile kullanır; `ApiKey__Enabled=true` ise panele `X-SoMine-Api-Key` değeri de verilmeli.
- Karşılama (onboarding) içeriği panelden düzenlenecekse `Onboarding__DemoContentPath=/app/config/onboarding-demo-content.json` ve compose'a yazılabilir bir **klasör** bağla (dosya değil; kayıt geçici dosya + yeniden adlandırma ile atomik yapılır): `- ./config:/app/config`. Klasör konteyner kullanıcısına yazılabilir olmalı: `mkdir -p /opt/somine/config && chown 1654:1654 /opt/somine/config` (.NET imajındaki `app` kullanıcısı). Dosya yoksa API gömülü listeyi döner; panelden ilk kayıtta dosya oluşur.

## 4. Firebase admin dosyasını yerleştir

Sunucuda bu dosya mevcut olmalı:

```bash
/opt/somine/secrets/firebase-admin.json
```

Dosya izinlerini sıkılaştır:

```bash
chmod 600 /opt/somine/secrets/firebase-admin.json
```

## 5. Lokal makinede image build et

Bu adımı kendi bilgisayarında çalıştır:

```bash
cd /Users/gokmenkucuk/Desktop/App/somine_api
docker buildx build \
  --platform linux/amd64 \
  -t somine-api:prod_v2 \
  --load \
  .

docker save somine-api:prod_v2 -o somine-api-prod_v2.tar
```

## 6. Sunucuya sadece gereken dosyaları at

Bu adımı kendi bilgisayarında çalıştır:

```bash
scp /Users/gokmenkucuk/Desktop/App/somine_api/docker-compose.server.yml root@46.224.146.102:/opt/somine/
scp /Users/gokmenkucuk/Desktop/App/somine_api/.env.production.example root@46.224.146.102:/opt/somine/
scp /Users/gokmenkucuk/Desktop/App/somine_api/somine-api-prod_v2.tar root@46.224.146.102:/opt/somine/
scp ~/Downloads/somineapp-57b41-firebase-adminsdk-fbsvc-b549360f13.json root@46.224.146.102:/opt/somine/secrets/firebase-admin.json
```

Not:

- Eğer `.env` dosyasını sunucuda zaten oluşturduysan `.env.production.example` atmana gerek yok.

## 7. Image'i sunucuda yükle

```bash
cd /opt/somine
docker load -i somine-api-prod_v2.tar
```

## 8. Uygulamayı ayağa kaldır

```bash
cd /opt/somine
docker compose -f docker-compose.server.yml up -d
```

## 9. Log kontrolü

```bash
docker compose -f docker-compose.server.yml logs -f somine-api
```

## 10. Health kontrolü

Sunucudan:

```bash
curl http://127.0.0.1:5181/health
```

Kendi makinenizden:

```bash
curl http://46.224.146.102:5181/health
```

Beklenen cevap:

```text
Healthy
```

## 11. Migration davranışı

Bu deployment `Database__ApplyMigrationsOnStartup=true` ile gelir.

Yani API container ayağa kalkarken veritabanı migration'larını uygular.

İlk çalıştırmada bu yüzden loglarda migration satırları görmen normaldir.

## 12. Güncelleme akışı

Yeni sürümde kendi bilgisayarında:

```bash
cd /Users/gokmenkucuk/Desktop/App/somine_api
docker buildx build \
  --platform linux/amd64 \
  -t somine-api:prod_v2 \
  --load \
  .

docker save somine-api:prod_v2 -o somine-api-prod_v2.tar
scp /Users/gokmenkucuk/Desktop/App/somine_api/somine-api-prod_v2.tar root@46.224.146.102:/opt/somine/
```

Sunucuda:

```bash
cd /opt/somine
docker load -i somine-api-prod_v2.tar
docker compose -f docker-compose.server.yml up -d
```

Not:

- Compose dosyası image tag'ini `.env` içindeki `SOMINE_API_IMAGE` değişkeninden okur.
- Varsayılan tag `somine-api:prod_v2` olarak ayarlanmıştır.
- Sonraki sürümlerde örnek: `somine-api:prod_v3`

## 13. Upload dosyaları

Local storage kullanılınca dosyalar bu klasörde kalır:

```bash
/opt/somine/uploads
```

Bu klasörün yedeğini ayrıca alman gerekir.

## 14. Şu anki önerilen production yaklaşımı

- Tek sunucu
- lokal image build + `docker compose`
- secret'lar `.env`
- Firebase admin dosyası volume mount
- upload klasörü bind mount

`Vault/Consul` şu aşamada gerekli değil.
