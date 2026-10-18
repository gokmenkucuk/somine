using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SomineApi.Infrastructure.Data.Migrations
{
    public partial class AddUserPremiumSnapshot : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "premium_expires_at_utc",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "premium_checked_at_utc",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "premium_expires_at_utc",
                table: "users");

            migrationBuilder.DropColumn(
                name: "premium_checked_at_utc",
                table: "users");
        }
    }
}
