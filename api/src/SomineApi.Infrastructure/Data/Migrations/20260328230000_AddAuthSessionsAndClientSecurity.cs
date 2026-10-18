using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SomineApi.Infrastructure.Data.Migrations
{
    public partial class AddAuthSessionsAndClientSecurity : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "auth_sessions",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    refresh_token_hash = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    client_id = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    platform = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    device_name = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    user_agent = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: true),
                    ip_address = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    expires_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    last_used_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    revoked_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    replaced_by_session_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_auth_sessions", x => x.id);
                    table.ForeignKey(
                        name: "FK_auth_sessions_auth_sessions_replaced_by_session_id",
                        column: x => x.replaced_by_session_id,
                        principalTable: "auth_sessions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_auth_sessions_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_auth_sessions_expires_at",
                table: "auth_sessions",
                column: "expires_at");

            migrationBuilder.CreateIndex(
                name: "IX_auth_sessions_refresh_token_hash",
                table: "auth_sessions",
                column: "refresh_token_hash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_auth_sessions_replaced_by_session_id",
                table: "auth_sessions",
                column: "replaced_by_session_id");

            migrationBuilder.CreateIndex(
                name: "IX_auth_sessions_user_id",
                table: "auth_sessions",
                column: "user_id");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "auth_sessions");
        }
    }
}
