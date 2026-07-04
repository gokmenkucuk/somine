using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SomineApi.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddRequestAndExceptionLogs : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "request_logs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    trace_id = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    request_id = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    method = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    path = table.Column<string>(type: "text", nullable: false),
                    query_string = table.Column<string>(type: "text", nullable: true),
                    route_template = table.Column<string>(type: "text", nullable: true),
                    controller_name = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    action_name = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    status_code = table.Column<int>(type: "integer", nullable: false),
                    duration_ms = table.Column<long>(type: "bigint", nullable: false),
                    ip_address = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    user_agent = table.Column<string>(type: "text", nullable: true),
                    client_id = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    source = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: true),
                    request_size_bytes = table.Column<long>(type: "bigint", nullable: true),
                    response_size_bytes = table.Column<long>(type: "bigint", nullable: true),
                    request_headers_json = table.Column<string>(type: "text", nullable: true),
                    request_body_preview = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_request_logs", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "exception_logs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    request_log_id = table.Column<Guid>(type: "uuid", nullable: true),
                    trace_id = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    exception_type = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    message = table.Column<string>(type: "text", nullable: false),
                    stack_trace = table.Column<string>(type: "text", nullable: true),
                    inner_exception_json = table.Column<string>(type: "text", nullable: true),
                    source = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: true),
                    path = table.Column<string>(type: "text", nullable: true),
                    method = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: true),
                    query_string = table.Column<string>(type: "text", nullable: true),
                    ip_address = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    user_agent = table.Column<string>(type: "text", nullable: true),
                    client_id = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: true),
                    is_handled = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_exception_logs", x => x.id);
                    table.ForeignKey(
                        name: "FK_exception_logs_request_logs_request_log_id",
                        column: x => x.request_log_id,
                        principalTable: "request_logs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_exception_logs_created_at",
                table: "exception_logs",
                column: "created_at");

            migrationBuilder.CreateIndex(
                name: "IX_exception_logs_exception_type",
                table: "exception_logs",
                column: "exception_type");

            migrationBuilder.CreateIndex(
                name: "IX_exception_logs_request_log_id",
                table: "exception_logs",
                column: "request_log_id");

            migrationBuilder.CreateIndex(
                name: "IX_exception_logs_trace_id",
                table: "exception_logs",
                column: "trace_id");

            migrationBuilder.CreateIndex(
                name: "IX_exception_logs_user_id",
                table: "exception_logs",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_request_logs_created_at",
                table: "request_logs",
                column: "created_at");

            migrationBuilder.CreateIndex(
                name: "IX_request_logs_path_created_at",
                table: "request_logs",
                columns: new[] { "path", "created_at" });

            migrationBuilder.CreateIndex(
                name: "IX_request_logs_trace_id",
                table: "request_logs",
                column: "trace_id");

            migrationBuilder.CreateIndex(
                name: "IX_request_logs_user_id",
                table: "request_logs",
                column: "user_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "exception_logs");

            migrationBuilder.DropTable(
                name: "request_logs");
        }
    }
}
