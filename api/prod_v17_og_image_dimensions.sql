-- =============================================================================
-- prod_v17_og_image_dimensions.sql
-- Migration: 20260802144654_AddOgImageDimensions
--
-- Amaç: OG önizleme görselinin piksel boyutlarının item üzerinde saklanması.
--       İstemci görseli zaten indirip gösterdiği için boyutu KENDİSİ ölçer ve
--       gönderir; sunucu görseli ASLA indirmez veya probe etmez. Böylece taze
--       bir cihazda ilk render'da en-boy oranı bilinir ve masonry düzeninde
--       kart yüksekliği oturduktan sonraki "zıplama" ortadan kalkar.
--
-- Kapsam: 2 kolon. Index yok, veri kaybı yok, geri alınabilir.
-- Idempotent: birden çok kez çalıştırılabilir.
--
-- pgAdmin'de tek blok olarak çalıştırın.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) items.og_image_width / items.og_image_height — OG görselinin piksel boyutu
--    Her ikisi de NULL bırakılabilir; boyutu göndermeyen eski istemciler
--    hiçbir değişiklik olmadan çalışmaya devam eder (istemci NULL gördüğünde
--    eski davranışına, yani ölçüp yerleştirmeye düşer).
--    Mobil istemci POST/PUT /api/items ile ogImageWidth/ogImageHeight gönderir.
--    Sunucu tarafı doğrulama: 0 < değer <= 20000 aralığı dışındaki her şey
--    (negatif, sıfır, absürt) 400 yerine sessizce NULL olarak saklanır.
-- -----------------------------------------------------------------------------
ALTER TABLE items
    ADD COLUMN IF NOT EXISTS og_image_width integer NULL;

ALTER TABLE items
    ADD COLUMN IF NOT EXISTS og_image_height integer NULL;

-- -----------------------------------------------------------------------------
-- 2) BACKFILL — GEREKMİYOR (bilinçli karar)
--
--    Mevcut satırlar NULL kalır. Boyutu sunucuda doldurmak, her og_image_url'i
--    indirip ölçmek anlamına gelirdi — bu tasarımın açıkça dışında tutuldu.
--    Boyutlar, kullanıcı içeriği bir sonraki kez kaydettiğinde/güncellediğinde
--    istemciden doğal olarak gelir. Eski satırlar bu arada bugünkü davranışla
--    (istemci tarafında ölçüm) sorunsuz görüntülenmeye devam eder.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 3) EF Core migration geçmişi — uygulamanın migration'ı tekrar uygulamaya
--    çalışmaması için kaydı işaretle.
-- -----------------------------------------------------------------------------
-- EF bu tabloyu kendisi yaratır; Database:ApplyMigrationsOnStartup kapalı olduğu
-- dönemlerde hiç oluşmamış olabileceği için önce varlığını garantiye alıyoruz.
CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260802144654_AddOgImageDimensions', '10.0.0')
ON CONFLICT ("MigrationId") DO NOTHING;

COMMIT;

-- =============================================================================
-- DOĞRULAMA (COMMIT sonrası ayrı ayrı çalıştırın)
-- =============================================================================
-- Kolonlar eklendi mi?
--   SELECT column_name, data_type, is_nullable
--   FROM information_schema.columns
--   WHERE table_name = 'items'
--     AND column_name IN ('og_image_width', 'og_image_height')
--   ORDER BY column_name;
--   -- beklenen: og_image_height | integer | YES
--   --           og_image_width  | integer | YES
--
-- Eski satırlar NULL mı? (backfill yok — hepsi NULL olmalı)
--   SELECT count(*) AS toplam,
--          count(og_image_width) AS boyutu_olan
--   FROM items;
--   -- beklenen: boyutu_olan = 0
--
-- Migration geçmişi işaretlendi mi?
--   SELECT "MigrationId" FROM "__EFMigrationsHistory" ORDER BY "MigrationId" DESC LIMIT 3;
--   -- en üstte: 20260802144654_AddOgImageDimensions
--
-- =============================================================================
-- GERİ ALMA (gerekirse)
-- =============================================================================
--   BEGIN;
--   ALTER TABLE items DROP COLUMN IF EXISTS og_image_height;
--   ALTER TABLE items DROP COLUMN IF EXISTS og_image_width;
--   DELETE FROM "__EFMigrationsHistory"
--     WHERE "MigrationId" = '20260802144654_AddOgImageDimensions';
--   COMMIT;
--
-- NOT: Eski imaja dönüş güvenlidir — kolonlar nullable ve eski kod onları
--      bilmiyor. Kolonlar yerinde bırakılsa bile eski sürüm sorunsuz çalışır.
-- =============================================================================
