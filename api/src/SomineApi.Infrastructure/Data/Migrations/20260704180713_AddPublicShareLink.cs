using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SomineApi.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddPublicShareLink : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "public_link_created_at_utc",
                table: "collection_shares",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "public_link_token",
                table: "collection_shares",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_collection_shares_public_link_token",
                table: "collection_shares",
                column: "public_link_token",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_collection_shares_public_link_token",
                table: "collection_shares");

            migrationBuilder.DropColumn(
                name: "public_link_created_at_utc",
                table: "collection_shares");

            migrationBuilder.DropColumn(
                name: "public_link_token",
                table: "collection_shares");
        }
    }
}
