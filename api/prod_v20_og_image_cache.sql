-- =============================================================================
-- prod_v20_og_image_cache.sql
-- Migration: 20261018125757_OgImageCache
--
-- Amaç: OG önizleme görsellerini sunucuda kalıcılaştırmak. Instagram/Facebook
--       CDN görsel adresleri imzalı ve birkaç günde süresi doluyor (`oe=`);
--       kaydedilen içeriklerin kapak görselleri herkes için kırılıyordu.
--       API artık harici og_image_url'i arka planda indirip kendi depolamasına
--       (/app/uploads/og/{sha256}.{ext}) kopyalıyor ve og_image_url'i kendi public
--       adresiyle ({Storage BaseUrl kökü}/public/og/{sha256}.{ext}) değiştiriyor.
--       - items.og_image_source_url: kopyalanan orijinal adres (izlenebilirlik;
--         ayrıca istemci eski adresi geri gönderirse kopya korunur)
--       - items.og_image_cache_failed_at: kaynak kalıcı olarak alınamadı
--         (403/404/geçersiz içerik) — backfill aynı item'ı yeniden denemez.
--
-- Kapsam: 2 nullable kolon. Index yok, veri kaybı yok, geri alınabilir.
-- Idempotent: birden çok kez çalıştırılabilir.
--
-- pgAdmin'de tek blok olarak çalıştırın. Yeni API imajından ÖNCE çalıştırın
-- (yeni imaj bu kolonları okur/yazar; eski imaj onları görmezden gelir).
-- Not: Database__ApplyMigrationsOnStartup=true ise API migration'ı kendisi de
-- uygular; bu script elle/önceden uygulamak içindir ve geçmişi işaretler.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) items.og_image_source_url / items.og_image_cache_failed_at
-- -----------------------------------------------------------------------------
ALTER TABLE items
    ADD COLUMN IF NOT EXISTS og_image_source_url text NULL;

ALTER TABLE items
    ADD COLUMN IF NOT EXISTS og_image_cache_failed_at timestamp with time zone NULL;

-- -----------------------------------------------------------------------------
-- 2) BACKFILL — SQL ile YAPILMAZ.
--    Mevcut item'ların görselleri API tarafından indirilir: yeni imajı bir kez
--    ImageCache__BackfillOnStartup=true ile başlatın (açılıştan ~30 sn sonra,
--    en yeniden eskiye 20'lik partilerle çalışır, bitince log'a özet yazar).
--    Süresi zaten dolmuş adresler (403/404) og_image_cache_failed_at ile işaretlenir.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 3) EF Core migration geçmişi
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261018125757_OgImageCache', '10.0.0')
ON CONFLICT ("MigrationId") DO NOTHING;

COMMIT;

-- =============================================================================
-- DOĞRULAMA (COMMIT sonrası ayrı ayrı çalıştırın)
-- =============================================================================
-- Kolonlar eklendi mi?
--   SELECT column_name, data_type, is_nullable
--   FROM information_schema.columns
--   WHERE table_name = 'items'
--     AND column_name IN ('og_image_source_url', 'og_image_cache_failed_at')
--   ORDER BY column_name;
--
-- Backfill ilerlemesi:
--   SELECT
--     count(*) FILTER (WHERE og_image_source_url IS NOT NULL)      AS kopyalanan,
--     count(*) FILTER (WHERE og_image_cache_failed_at IS NOT NULL) AS kalici_hatali,
--     count(*) FILTER (WHERE og_image_url LIKE 'http%'
--                        AND og_image_source_url IS NULL
--                        AND og_image_cache_failed_at IS NULL)     AS bekleyen_veya_kendi_adresimiz
--   FROM items WHERE is_deleted = false;
--
-- Migration geçmişi:
--   SELECT "MigrationId" FROM "__EFMigrationsHistory" ORDER BY "MigrationId" DESC LIMIT 3;
--   -- en üstte: 20261018125757_OgImageCache
--
-- =============================================================================
-- GERİ ALMA (gerekirse)
-- =============================================================================
-- Önce kopyalanan item'ların orijinal adresini geri yazmak isterseniz:
--   UPDATE items SET og_image_url = og_image_source_url
--     WHERE og_image_source_url IS NOT NULL;
-- Sonra:
--   BEGIN;
--   ALTER TABLE items DROP COLUMN IF EXISTS og_image_cache_failed_at;
--   ALTER TABLE items DROP COLUMN IF EXISTS og_image_source_url;
--   DELETE FROM "__EFMigrationsHistory"
--     WHERE "MigrationId" = '20261018125757_OgImageCache';
--   COMMIT;
--
-- NOT: Eski imaja dönüş geri alma GEREKTİRMEZ — kolonlar nullable, eski kod
--      onları bilmiyor; /public/og/... adresleri ise eski imajda 404 döner
--      (o durumda yukarıdaki UPDATE ile orijinal adresler geri yazılabilir).
-- =============================================================================
