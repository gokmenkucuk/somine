using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SomineApi.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddCategoryPublicLink : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "public_link_created_at_utc",
                table: "categories",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "public_link_token",
                table: "categories",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_categories_public_link_token",
                table: "categories",
                column: "public_link_token",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_categories_public_link_token",
                table: "categories");

            migrationBuilder.DropColumn(
                name: "public_link_created_at_utc",
                table: "categories");

            migrationBuilder.DropColumn(
                name: "public_link_token",
                table: "categories");
        }
    }
}
