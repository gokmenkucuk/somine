using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SomineApi.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class UgcReportsAndBlocks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "content_reports",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    reporter_id = table.Column<Guid>(type: "uuid", nullable: false),
                    reported_user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    share_id = table.Column<Guid>(type: "uuid", nullable: true),
                    category_id = table.Column<Guid>(type: "uuid", nullable: true),
                    reason = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    note = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    status = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false, defaultValue: "Open")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_content_reports", x => x.id);
                    table.ForeignKey(
                        name: "FK_content_reports_users_reported_user_id",
                        column: x => x.reported_user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_content_reports_users_reporter_id",
                        column: x => x.reporter_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "user_blocks",
                columns: table => new
                {
                    blocker_id = table.Column<Guid>(type: "uuid", nullable: false),
                    blocked_id = table.Column<Guid>(type: "uuid", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_blocks", x => new { x.blocker_id, x.blocked_id });
                    table.ForeignKey(
                        name: "FK_user_blocks_users_blocked_id",
                        column: x => x.blocked_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_user_blocks_users_blocker_id",
                        column: x => x.blocker_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_content_reports_reported_user_id",
                table: "content_reports",
                column: "reported_user_id");

            migrationBuilder.CreateIndex(
                name: "IX_content_reports_reporter_id",
                table: "content_reports",
                column: "reporter_id");

            migrationBuilder.CreateIndex(
                name: "IX_content_reports_status_created_at",
                table: "content_reports",
                columns: new[] { "status", "created_at" });

            migrationBuilder.CreateIndex(
                name: "IX_user_blocks_blocked_id",
                table: "user_blocks",
                column: "blocked_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "content_reports");

            migrationBuilder.DropTable(
                name: "user_blocks");
        }
    }
}
