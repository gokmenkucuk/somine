using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SomineApi.Infrastructure.Data.Migrations
{
    /// <summary>
    /// pg_trgm + unaccent tabanlı arama altyapısı.
    ///
    /// NOT: EF'in ürettiği <c>AlterDatabase().Annotation("Npgsql:PostgresExtension:...")</c> çağrısı
    /// bilinçli olarak elle kaldırıldı. Npgsql, AlterDatabase için modeldeki TÜM extension'ları
    /// (<c>vector</c> dahil) yeniden yayınlıyor; <c>vector</c> ise prod'da mevcut olmadığından
    /// <c>CREATE EXTENSION vector</c> ifadesi migration'ı patlatırdı. Extension'lar bu yüzden
    /// yalnızca aşağıdaki hedefli, idempotent ham SQL ile oluşturulur.
    /// Model snapshot pg_trgm/unaccent annotation'larını içerdiği için model drift oluşmaz.
    /// </summary>
    public partial class AddTrigramSearch : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
                """);

            migrationBuilder.Sql("""
                CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
                """);

            // IMMUTABLE sarmalayıcı.
            // unaccent(text) STABLE'dır (kullanılacak sözlüğü çalışma anında search_path'ten çözer),
            // bu yüzden doğrudan functional index'te kullanılamaz. İki argümanlı
            // unaccent(regdictionary, text) biçimi ise PostgreSQL tarafından IMMUTABLE olarak
            // tanımlanmıştır; sözlük adı sabitlendiğinde sarmalayıcı da gerçekten immutable olur.
            // Bu, PostgreSQL dokümantasyonunun unaccent ile index'leme için önerdiği yoldur.
            migrationBuilder.Sql("""
                CREATE OR REPLACE FUNCTION public.somine_search_normalize(source_text text)
                RETURNS text
                LANGUAGE sql
                IMMUTABLE
                STRICT
                PARALLEL SAFE
                AS $func$
                    SELECT public.unaccent('public.unaccent'::regdictionary, lower(source_text))
                $func$;
                """);

            foreach (var column in new[] { "og_title", "note", "url", "og_description" })
            {
                migrationBuilder.Sql($"""
                    CREATE INDEX IF NOT EXISTS ix_items_{column}_trgm
                        ON items
                        USING gin (public.somine_search_normalize({column}) public.gin_trgm_ops);
                    """);
            }
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            foreach (var column in new[] { "og_title", "note", "url", "og_description" })
            {
                migrationBuilder.Sql($"DROP INDEX IF EXISTS ix_items_{column}_trgm;");
            }

            migrationBuilder.Sql("DROP FUNCTION IF EXISTS public.somine_search_normalize(text);");

            // vector extension'ına dokunulmaz; bu migration onu oluşturmadı.
            migrationBuilder.Sql("DROP EXTENSION IF EXISTS unaccent;");
            migrationBuilder.Sql("DROP EXTENSION IF EXISTS pg_trgm;");
        }
    }
}
