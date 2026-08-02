using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SomineApi.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddOgImageDimensions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "og_image_height",
                table: "items",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "og_image_width",
                table: "items",
                type: "integer",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "og_image_height",
                table: "items");

            migrationBuilder.DropColumn(
                name: "og_image_width",
                table: "items");
        }
    }
}
