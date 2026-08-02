-- =============================================================================
-- prod_v15_reminder_notifications.sql
-- Migration: 20260802101050_AddReminderNotifications
--
-- Amaç: Sunucunun vakti gelen hatırlatıcılar için uygulama içi bildirim
--       üretebilmesi. Hatırlatıcılar yerel duvar saati olarak saklandığı
--       (reminder_date + reminder_hour + reminder_minute) ve kullanıcıda zaman
--       dilimi bilgisi olmadığı için sunucu "09:00"ın hangi UTC anına denk
--       geldiğini bilemiyordu. users.time_zone_id bunu çözer.
--
-- Kapsam: 1 kolon + 1 index. Veri kaybı yok, geri alınabilir.
-- Idempotent: birden çok kez çalıştırılabilir.
--
-- pgAdmin'de tek blok olarak çalıştırın.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) users.time_zone_id — kullanıcının IANA zaman dilimi kimliği
--    NULL bırakılabilir; sunucu NULL için "Europe/Istanbul" varsayar
--    (ReminderNotifications:DefaultTimeZoneId ile yapılandırılabilir).
--    Mobil istemci PUT /api/users/me ile bu alanı gönderir.
-- -----------------------------------------------------------------------------
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS time_zone_id character varying(64) NULL;

-- -----------------------------------------------------------------------------
-- 2) Arka plan tarayıcısı için index
--    Servis her dakika "aktif + tarihi gelmiş" hatırlatıcıları sorguluyor.
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS "IX_reminders_is_active_reminder_date"
    ON reminders (is_active, reminder_date);

-- -----------------------------------------------------------------------------
-- 3) BACKFILL — GEREKMİYOR (bilinçli karar)
--
--    time_zone_id NULL kalan tüm kullanıcılar varsayılan Europe/Istanbul ile
--    çalışır; mevcut hatırlatıcılar hiçbir dokunuş olmadan doğru anda tetiklenir.
--    (Türkiye 2016'dan beri kalıcı UTC+03:00, yaz saati yok.)
--
--    Kullanıcıları başka bir bölgeye taşımak isterseniz:
--        UPDATE users SET time_zone_id = 'Europe/Berlin' WHERE id = '...';
--
--    Eski hatırlatıcıların toplu bildirim yağdırması, uygulama tarafındaki
--    ReminderNotifications:CatchUpWindow (varsayılan 24 saat) ile engellenir —
--    bundan daha eski tetikleme anları ıskalanmış sayılır. SQL tarafında
--    last_triggered doldurmaya gerek yoktur.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 4) EF Core migration geçmişi — uygulamanın migration'ı tekrar uygulamaya
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
VALUES ('20260802101050_AddReminderNotifications', '10.0.0')
ON CONFLICT ("MigrationId") DO NOTHING;

COMMIT;

-- =============================================================================
-- DOĞRULAMA (COMMIT sonrası ayrı ayrı çalıştırın)
-- =============================================================================
-- Kolon eklendi mi?
--   SELECT column_name, data_type, character_maximum_length, is_nullable
--   FROM information_schema.columns
--   WHERE table_name = 'users' AND column_name = 'time_zone_id';
--   -- beklenen: time_zone_id | character varying | 64 | YES
--
-- Index oluştu mu?
--   SELECT indexname FROM pg_indexes
--   WHERE tablename = 'reminders' AND indexname = 'IX_reminders_is_active_reminder_date';
--
-- Migration geçmişi işaretlendi mi?
--   SELECT "MigrationId" FROM "__EFMigrationsHistory" ORDER BY "MigrationId" DESC LIMIT 3;
--   -- en üstte: 20260802101050_AddReminderNotifications
--
-- =============================================================================
-- GERİ ALMA (gerekirse)
-- =============================================================================
--   BEGIN;
--   DROP INDEX IF EXISTS "IX_reminders_is_active_reminder_date";
--   ALTER TABLE users DROP COLUMN IF EXISTS time_zone_id;
--   DELETE FROM "__EFMigrationsHistory"
--     WHERE "MigrationId" = '20260802101050_AddReminderNotifications';
--   COMMIT;
--
-- NOT: Eski imaja dönüş güvenlidir — kolon nullable ve eski kod onu bilmiyor.
-- =============================================================================
