-- =============================================================================
-- prod_v16_fix_repeat_frequency.sql
-- Migration: YOK — bu saf bir VERİ düzeltmesidir.
--
-- Şema değişmiyor (kolon/index/tip dokunulmuyor), bu yüzden bilerek
-- __EFMigrationsHistory'ye kayıt EKLENMİYOR. EF'in migration listesi bu dosyadan
-- etkilenmez; yanlışlıkla bir migration'ı "uygulanmış" işaretlemek ileride gerçek
-- migration'ın atlanmasına yol açardı.
--
-- Amaç: reminders.repeat_type alanındaki mobil kaynaklı tip karışıklığını düzeltmek.
--
-- Kök neden (uygulama tarafında GİDERİLDİ):
--   Sunucudaki RepeatFrequency enum'unun sırası mobildekinden farklıydı —
--     sunucu : ... Weekends=6, CustomDays=7,    CustomMinutes=8
--     mobil  : ... weekends=6, customMinutes=7, customDays=8
--   Mobil istemci repeat.index'i TAM SAYI olarak gönderdiği (ve sunucu enum'u
--   JSON'a tam sayı olarak yazdığı) için 7 ve 8 ters eşleşiyordu. Kullanıcı
--   "her 15 dakikada bir" seçtiğinde satır veritabanına
--       repeat_type='CustomDays' + custom_repeat_minutes=15
--   olarak yazılıyordu. Gidiş-dönüş kendi içinde tutarlı olduğu için kullanıcı
--   fark etmiyordu, ama saklanan veri semantik olarak YANLIŞTI.
--
--   Firebase migrator'ı (FirebaseContentMigrationRunner) tipi İSİMDEN ayrıştırdığı
--   için o kayıtları DOĞRU yazmıştı. Yani tabloda iki farklı yorum yan yana duruyor.
--
--   Sunucu enum'u artık mobille birebir hizalandı (CustomMinutes=7, CustomDays=8),
--   dolayısıyla YENİ kayıtlar doğru yazılıyor ve migrator kayıtları da artık mobile
--   doğru gösteriliyor. Bu betik GEÇMİŞ kayıtları düzeltir.
--
-- NOT: repeat_type kolonu METİN olarak saklanıyor (EF HasConversion<string>()),
--      bu yüzden enum'un sayısal sırasını değiştirmek saklanan metni etkilemedi —
--      yalnızca JSON tam sayı <-> üye eşlemesi düzeldi. Aşağıdaki düzeltme de
--      metin değerleri üzerinde çalışır.
--
-- Ayırt edici ölçüt: hangi custom alanın DOLU olduğu.
-- Belirsiz satırlara (iki alan da dolu / iki alan da boş) DOKUNULMAZ.
-- Idempotent: birden çok kez çalıştırılabilir (düzeltilmiş satırlar artık eşleşmez).
--
-- pgAdmin'de tek blok olarak çalıştırın.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0) ÖNCE BUNU ÇALIŞTIRIN — kaç kayıt etkilenecek?
--    (Salt okunur; UPDATE'ten önce tek başına çalıştırıp sonucu görün.)
-- -----------------------------------------------------------------------------
--   SELECT
--       CASE
--           WHEN repeat_type = 'CustomDays'
--                AND COALESCE(custom_repeat_minutes, 0) > 0
--                AND COALESCE(custom_repeat_days, 0) = 0
--               THEN 'DUZELTILECEK: CustomDays -> CustomMinutes (mobilden yanlis yazilmis)'
--           WHEN repeat_type = 'CustomMinutes'
--                AND COALESCE(custom_repeat_days, 0) > 0
--                AND COALESCE(custom_repeat_minutes, 0) = 0
--               THEN 'DUZELTILECEK: CustomMinutes -> CustomDays'
--           WHEN COALESCE(custom_repeat_minutes, 0) > 0
--                AND COALESCE(custom_repeat_days, 0) > 0
--               THEN 'BELIRSIZ (iki alan da dolu) - DOKUNULMAYACAK'
--           WHEN COALESCE(custom_repeat_minutes, 0) = 0
--                AND COALESCE(custom_repeat_days, 0) = 0
--               THEN 'BELIRSIZ (iki alan da bos) - DOKUNULMAYACAK'
--           ELSE 'TUTARLI - DOKUNULMAYACAK'
--       END AS durum,
--       repeat_type,
--       COUNT(*) AS kayit_sayisi
--   FROM reminders
--   WHERE repeat_type IN ('CustomDays', 'CustomMinutes')
--   GROUP BY 1, 2
--   ORDER BY 1, 2;
--
--   Etkilenen satırları tek tek görmek isterseniz:
--     SELECT id, item_id, repeat_type, custom_repeat_days, custom_repeat_minutes
--     FROM reminders
--     WHERE (repeat_type = 'CustomDays'
--            AND COALESCE(custom_repeat_minutes, 0) > 0
--            AND COALESCE(custom_repeat_days, 0) = 0)
--        OR (repeat_type = 'CustomMinutes'
--            AND COALESCE(custom_repeat_days, 0) > 0
--            AND COALESCE(custom_repeat_minutes, 0) = 0)
--     ORDER BY repeat_type, id;
-- -----------------------------------------------------------------------------

BEGIN;

-- -----------------------------------------------------------------------------
-- 1) Tek atomik UPDATE ile iki yönlü düzeltme
--
--    Neden tek CASE'li UPDATE? İki ayrı UPDATE art arda çalıştırılsaydı, ilkinin
--    düzelttiği satırlar ikincisinin WHERE'ine takılıp geri çevrilebilirdi.
--    Tek ifade, satırların ESKİ hâline bakarak karar verir — sıra tuzağı yok.
--
--    "Dolu" ölçütü NULL değil, > 0 olarak tanımlandı; böylece uygulamadaki
--    ReminderSchedule.EffectiveRepeatType güvenlik ağıyla BİREBİR aynı davranıyor
--    (o da 0/NULL değeri "boş" sayıyor). Aksi hâlde custom_repeat_days = 0 gibi
--    satırlarda SQL ile çalışma zamanı farklı karar verirdi.
-- -----------------------------------------------------------------------------
UPDATE reminders
SET repeat_type = CASE
        WHEN repeat_type = 'CustomDays' THEN 'CustomMinutes'
        ELSE 'CustomDays'
    END
WHERE (
        -- Mobilden gelmiş, dakika bazlı olması gerekirken CustomDays yazılmış
        repeat_type = 'CustomDays'
        AND COALESCE(custom_repeat_minutes, 0) > 0
        AND COALESCE(custom_repeat_days, 0) = 0
      )
   OR (
        -- Ters yön: gün bazlı olması gerekirken CustomMinutes yazılmış
        repeat_type = 'CustomMinutes'
        AND COALESCE(custom_repeat_days, 0) > 0
        AND COALESCE(custom_repeat_minutes, 0) = 0
      );

-- -----------------------------------------------------------------------------
-- 2) BELİRSİZ SATIRLAR — bilinçli olarak DOKUNULMUYOR
--
--    * İki custom alanı da dolu  -> hangisinin kastedildiği veriden anlaşılamaz.
--    * İki custom alanı da boş   -> tekrar aralığı zaten tanımsız; tip değiştirmek
--                                   davranışı düzeltmez.
--
--    Bu satırlar çalışma zamanında güvenli davranır: EffectiveRepeatType yalnızca
--    tek taraf boş / diğeri doluyken devreye girdiği için belirsiz satırlarda
--    saklanan tip aynen kullanılır, custom aralığı geçersizse
--    ReminderScheduleCalculator tekrarsız (None) gibi ele alır.
--
--    Sayılarını görmek için (COMMIT sonrası):
--      SELECT repeat_type, custom_repeat_days, custom_repeat_minutes, COUNT(*)
--      FROM reminders
--      WHERE repeat_type IN ('CustomDays', 'CustomMinutes')
--        AND (
--              (COALESCE(custom_repeat_days, 0) > 0 AND COALESCE(custom_repeat_minutes, 0) > 0)
--           OR (COALESCE(custom_repeat_days, 0) = 0 AND COALESCE(custom_repeat_minutes, 0) = 0)
--            )
--      GROUP BY 1, 2, 3
--      ORDER BY 1, 2, 3;
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 3) next_trigger / last_triggered — SIFIRLAMAYA GEREK YOK
--
--    Sıradaki tetikleme anı saklanmıyor; arka plan servisi her turda
--    ReminderScheduleCalculator ile yeniden hesaplıyor. Düzeltilmiş satırlar bir
--    sonraki taramada doğru aralıkla devam eder. last_triggered'a dokunmak ise
--    geçmiş bildirimlerin tekrar üretilmesine yol açardı.
-- -----------------------------------------------------------------------------

COMMIT;

-- =============================================================================
-- DOĞRULAMA (COMMIT sonrası ayrı ayrı çalıştırın)
-- =============================================================================
-- Tutarsız satır kalmadı mı? (beklenen: 0 satır)
--   SELECT id, repeat_type, custom_repeat_days, custom_repeat_minutes
--   FROM reminders
--   WHERE (repeat_type = 'CustomDays'
--          AND COALESCE(custom_repeat_minutes, 0) > 0
--          AND COALESCE(custom_repeat_days, 0) = 0)
--      OR (repeat_type = 'CustomMinutes'
--          AND COALESCE(custom_repeat_days, 0) > 0
--          AND COALESCE(custom_repeat_minutes, 0) = 0);
--
-- Genel dağılım:
--   SELECT repeat_type, COUNT(*) FROM reminders GROUP BY 1 ORDER BY 2 DESC;
--
-- Beklenmeyen bir repeat_type değeri var mı? (beklenen: 0 satır)
--   SELECT DISTINCT repeat_type FROM reminders
--   WHERE repeat_type NOT IN ('None','Daily','Weekly','Monthly','Yearly',
--                             'Weekdays','Weekends','CustomMinutes','CustomDays');
--
-- =============================================================================
-- GERİ ALMA
-- =============================================================================
-- Bu düzeltme kendi tersidir: aynı WHERE koşulu düzeltilmiş satırlarla artık
-- eşleşmediği için betiği tekrar çalıştırmak satırları GERİ ÇEVİRMEZ (idempotent).
-- Gerçekten geri almak isterseniz, önce 0) adımındaki SELECT ile etkilenen id'leri
-- kaydedin; geri alma o id listesi üzerinden yapılmalıdır:
--   BEGIN;
--   UPDATE reminders
--   SET repeat_type = CASE WHEN repeat_type = 'CustomMinutes' THEN 'CustomDays'
--                          ELSE 'CustomMinutes' END
--   WHERE id IN ( ... kaydettiğiniz id listesi ... );
--   COMMIT;
--
-- NOT: Eski uygulama imajına dönerseniz veri düzeltmesi yerinde kalır; o sürümdeki
-- EffectiveRepeatType güvenlik ağı düzeltilmiş satırları da doğru yorumlar, ancak
-- mobile giden tam sayı yeniden ters eşleşeceği için imajı geri almak yerine ileri
-- gitmek tercih edilmelidir.
-- =============================================================================
