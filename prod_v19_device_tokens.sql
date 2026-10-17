-- =============================================================================
-- prod_v19_device_tokens.sql
-- Migration: 20261017151458_AddDeviceTokens
--
-- Amaç: Uzak bildirim (Firebase Cloud Messaging → APNs). Uygulama kapalıyken
--       paylaşım isteği / kabul / ret bildirimlerinin telefona ulaşması için
--       cihaz FCM token'ları saklanır.
--       - device_tokens: kullanıcı başına cihaz token'ları; token küresel benzersiz.
--
-- Kapsam: 1 yeni tablo + index. Mevcut tablolara dokunmaz, veri kaybı yok.
-- Idempotent: birden çok kez çalıştırılabilir.
--
-- pgAdmin'de tek blok olarak çalıştırın. Yeni API imajından ÖNCE çalıştırın
-- (yeni imaj bu tabloyu okur/yazar; eski imaj tabloyu görmezden gelir).
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) device_tokens — FCM kayıt token'ları. Kullanıcı silinince CASCADE ile gider;
--    API hesap silme ucu ayrıca açıkça siler. FCM "unregistered" dediğinde API
--    satırı kendisi temizler.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS device_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token character varying(512) NOT NULL,
    platform character varying(16) NULL,
    locale character varying(16) NULL,
    created_at timestamp with time zone NOT NULL DEFAULT (NOW()),
    updated_at timestamp with time zone NOT NULL DEFAULT (NOW()),
    last_seen_at timestamp with time zone NOT NULL DEFAULT (NOW()),
    CONSTRAINT "PK_device_tokens" PRIMARY KEY (id),
    CONSTRAINT "FK_device_tokens_users_user_id" FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_device_tokens_token" ON device_tokens (token);
CREATE INDEX IF NOT EXISTS "IX_device_tokens_user_id" ON device_tokens (user_id);

-- -----------------------------------------------------------------------------
-- 2) EF Core migration geçmişi
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261017151458_AddDeviceTokens', '10.0.0')
ON CONFLICT ("MigrationId") DO NOTHING;

COMMIT;

-- =============================================================================
-- DOĞRULAMA (COMMIT sonrası ayrı ayrı çalıştırın)
-- =============================================================================
--   SELECT to_regclass('public.device_tokens');
--   -- beklenen: NULL olmamalı
--
-- Kayıtlı cihaz sayısı (platform bazında):
--   SELECT platform, locale, COUNT(*) FROM device_tokens GROUP BY platform, locale;
--
-- 60 günden uzun süredir görülmeyen (bayat) token'ları temizlemek için (isteğe bağlı):
--   DELETE FROM device_tokens WHERE last_seen_at < NOW() - INTERVAL '60 days';
-- =============================================================================
