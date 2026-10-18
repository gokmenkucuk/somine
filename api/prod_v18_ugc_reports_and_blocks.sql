-- =============================================================================
-- prod_v18_ugc_reports_and_blocks.sql
-- Migration: 20261017131137_UgcReportsAndBlocks
--
-- Amaç: App Store Guideline 1.2 (kullanıcı üretimi içerik) kontrolleri.
--       - user_blocks: kullanıcı engelleme (engelleyen, engellenen) çifti benzersiz.
--       - content_reports: paylaşılan koleksiyon şikâyetleri (inceleme kuyruğu).
--
-- Kapsam: 2 yeni tablo + index. Mevcut tablolara dokunmaz, veri kaybı yok.
-- Idempotent: birden çok kez çalıştırılabilir.
--
-- pgAdmin'de tek blok olarak çalıştırın. Yeni API imajından ÖNCE çalıştırın
-- (yeni imaj bu tabloları okur; eski imaj tabloları görmezden gelir).
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) content_reports — şikâyetler. share_id / category_id bilinçli olarak FK
--    değil: paylaşım geri çekilse de şikâyet kaydı inceleme için kalır.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS content_reports (
    id uuid NOT NULL,
    reporter_id uuid NOT NULL,
    reported_user_id uuid NOT NULL,
    share_id uuid NULL,
    category_id uuid NULL,
    reason character varying(32) NOT NULL,
    note character varying(500) NULL,
    created_at timestamp with time zone NOT NULL DEFAULT (NOW()),
    status character varying(32) NOT NULL DEFAULT 'Open',
    CONSTRAINT "PK_content_reports" PRIMARY KEY (id),
    CONSTRAINT "FK_content_reports_users_reported_user_id" FOREIGN KEY (reported_user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT "FK_content_reports_users_reporter_id" FOREIGN KEY (reporter_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_content_reports_reported_user_id" ON content_reports (reported_user_id);
CREATE INDEX IF NOT EXISTS "IX_content_reports_reporter_id" ON content_reports (reporter_id);
CREATE INDEX IF NOT EXISTS "IX_content_reports_status_created_at" ON content_reports (status, created_at);

-- -----------------------------------------------------------------------------
-- 2) user_blocks — engellemeler. PK (blocker_id, blocked_id) çifti benzersiz kılar.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_blocks (
    blocker_id uuid NOT NULL,
    blocked_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT (NOW()),
    CONSTRAINT "PK_user_blocks" PRIMARY KEY (blocker_id, blocked_id),
    CONSTRAINT "FK_user_blocks_users_blocked_id" FOREIGN KEY (blocked_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT "FK_user_blocks_users_blocker_id" FOREIGN KEY (blocker_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_user_blocks_blocked_id" ON user_blocks (blocked_id);

-- -----------------------------------------------------------------------------
-- 3) EF Core migration geçmişi
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261017131137_UgcReportsAndBlocks', '10.0.0')
ON CONFLICT ("MigrationId") DO NOTHING;

COMMIT;

-- =============================================================================
-- DOĞRULAMA (COMMIT sonrası ayrı ayrı çalıştırın)
-- =============================================================================
--   SELECT to_regclass('public.user_blocks'), to_regclass('public.content_reports');
--   -- beklenen: iki satır da NULL olmamalı
--
-- Açık şikâyetler (ops inceleme kuyruğu, 24 saat hedefi):
--   SELECT id, reporter_id, reported_user_id, share_id, category_id, reason, note, created_at
--   FROM content_reports WHERE status = 'Open' ORDER BY created_at;
--
-- İnceleme sonrası:
--   UPDATE content_reports SET status = 'ActionTaken' WHERE id = '<id>';   -- veya 'Dismissed' / 'Reviewed'
-- =============================================================================
