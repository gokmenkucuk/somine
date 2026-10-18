using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/export")]
[Authorize]
[EnableRateLimiting("export")]
public class ExportController : ControllerBase
{
    private readonly SomineDbContext _dbContext;

    public ExportController(SomineDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    // Kullanıcının silinmemiş item'ları + kategori listesi; free katman dahil herkese açık.
    // Büyük listelerde belleği şişirmemek için AsNoTracking + AsAsyncEnumerable ile
    // doğrudan Response.Body'ye akıtılır.
    [HttpGet]
    public async Task<IActionResult> Export(
        [FromQuery] string format = "json",
        CancellationToken cancellationToken = default)
    {
        var userId = HttpContext.GetUserId();

        var normalizedFormat = format.Trim().ToLowerInvariant();
        if (normalizedFormat != "json" && normalizedFormat != "csv")
            return BadRequest(new { error = "Invalid format. Use 'json' or 'csv'." });

        var email = await _dbContext.Users
            .AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => u.Email)
            .FirstOrDefaultAsync(cancellationToken);

        var categories = await _dbContext.Categories
            .AsNoTracking()
            .Where(c => c.UserId == userId)
            .OrderBy(c => c.SortOrder)
            .ThenBy(c => c.CreatedAt)
            .Select(c => new { c.Id, c.Name, c.Icon, c.Color })
            .ToListAsync(cancellationToken);

        var items = _dbContext.Items
            .AsNoTracking()
            .Where(i => i.UserId == userId && !i.IsDeleted)
            .OrderBy(i => i.CreatedAt)
            .Select(i => new ExportItemRow(
                i.Id,
                i.Type.ToString(),
                i.Url,
                i.Note,
                i.OgTitle,
                i.OgDescription,
                i.Category != null ? i.Category.Name : null,
                i.IsFavorite,
                i.CreatedAt,
                i.LastOpenedAt))
            .AsAsyncEnumerable();

        var exportedAt = DateTime.UtcNow;
        var fileNameStamp = exportedAt.ToString("yyyyMMdd-HHmmss");

        if (normalizedFormat == "csv")
        {
            Response.ContentType = "text/csv; charset=utf-8";
            Response.Headers.ContentDisposition = $"attachment; filename=\"somine-export-{fileNameStamp}.csv\"";

            await using var writer = new StreamWriter(Response.Body, new UTF8Encoding(false), leaveOpen: true)
            {
                NewLine = "\r\n" // RFC 4180
            };

            await writer.WriteLineAsync("Id,Type,Url,Note,OgTitle,OgDescription,Category,IsFavorite,CreatedAt,LastOpenedAt");

            await foreach (var item in items.WithCancellation(cancellationToken))
            {
                var fields = new[]
                {
                    item.Id.ToString(),
                    item.Type,
                    item.Url,
                    item.Note,
                    item.OgTitle,
                    item.OgDescription,
                    item.CategoryName,
                    item.IsFavorite ? "true" : "false",
                    item.CreatedAt.ToString("O"),
                    item.LastOpenedAt?.ToString("O")
                };

                await writer.WriteLineAsync(string.Join(',', fields.Select(CsvEscape)));
            }

            await writer.FlushAsync(cancellationToken);
            return new EmptyResult();
        }

        Response.ContentType = "application/json; charset=utf-8";
        Response.Headers.ContentDisposition = $"attachment; filename=\"somine-export-{fileNameStamp}.json\"";

        await using var jsonWriter = new Utf8JsonWriter(Response.Body);

        jsonWriter.WriteStartObject();
        jsonWriter.WriteString("exportedAt", exportedAt);

        jsonWriter.WriteStartObject("user");
        jsonWriter.WriteString("email", email);
        jsonWriter.WriteEndObject();

        jsonWriter.WriteStartArray("categories");
        foreach (var category in categories)
        {
            jsonWriter.WriteStartObject();
            jsonWriter.WriteString("id", category.Id);
            jsonWriter.WriteString("name", category.Name);
            jsonWriter.WriteString("icon", category.Icon);
            jsonWriter.WriteString("color", category.Color);
            jsonWriter.WriteEndObject();
        }
        jsonWriter.WriteEndArray();

        jsonWriter.WriteStartArray("items");
        await foreach (var item in items.WithCancellation(cancellationToken))
        {
            jsonWriter.WriteStartObject();
            jsonWriter.WriteString("id", item.Id);
            jsonWriter.WriteString("type", item.Type);
            jsonWriter.WriteString("url", item.Url);
            jsonWriter.WriteString("note", item.Note);
            jsonWriter.WriteString("ogTitle", item.OgTitle);
            jsonWriter.WriteString("ogDescription", item.OgDescription);
            jsonWriter.WriteString("categoryName", item.CategoryName);
            jsonWriter.WriteBoolean("isFavorite", item.IsFavorite);
            jsonWriter.WriteString("createdAt", item.CreatedAt);
            if (item.LastOpenedAt.HasValue)
                jsonWriter.WriteString("lastOpenedAt", item.LastOpenedAt.Value);
            else
                jsonWriter.WriteNull("lastOpenedAt");
            jsonWriter.WriteEndObject();

            if (jsonWriter.BytesPending > 64 * 1024)
                await jsonWriter.FlushAsync(cancellationToken);
        }
        jsonWriter.WriteEndArray();

        jsonWriter.WriteEndObject();
        await jsonWriter.FlushAsync(cancellationToken);
        return new EmptyResult();
    }

    // RFC 4180: virgül, çift tırnak veya satır sonu içeren alanlar tırnaklanır;
    // içerideki çift tırnaklar ikilenir.
    private static string CsvEscape(string? value)
    {
        if (string.IsNullOrEmpty(value))
            return string.Empty;

        var mustQuote = value.Contains(',') || value.Contains('"') || value.Contains('\n') || value.Contains('\r');
        if (!mustQuote)
            return value;

        return $"\"{value.Replace("\"", "\"\"")}\"";
    }

    private sealed record ExportItemRow(
        Guid Id,
        string Type,
        string? Url,
        string? Note,
        string? OgTitle,
        string? OgDescription,
        string? CategoryName,
        bool IsFavorite,
        DateTime CreatedAt,
        DateTime? LastOpenedAt);
}
