using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SomineApi.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddReminderNotifications : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "time_zone_id",
                table: "users",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_reminders_is_active_reminder_date",
                table: "reminders",
                columns: new[] { "is_active", "reminder_date" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_reminders_is_active_reminder_date",
                table: "reminders");

            migrationBuilder.DropColumn(
                name: "time_zone_id",
                table: "users");
        }
    }
}
