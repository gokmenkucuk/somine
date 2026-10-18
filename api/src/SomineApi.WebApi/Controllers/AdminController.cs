using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Admin;
using SomineApi.WebApi.Onboarding;

namespace SomineApi.WebApi.Controllers;

public sealed record AdminReportPersonDto(Guid Id, string? DisplayName, string? Username);

public sealed record AdminReportDto(
    Guid Id,
    string Reason,
    string? Note,
    string Status,
    DateTime CreatedAt,
    AdminReportPersonDto Reporter,
    AdminReportPersonDto Reported,
    Guid? ShareId,
    Guid? CategoryId,
    string? CollectionName,
    string? ShareStatus);

public sealed record AdminResolveReportRequest(string? Action);

/// <summary>
/// GSO Studio yönetim paneli uçları (sunucudan sunucuya). Kullanıcı JWT'si değil,
/// <c>X-Admin-Key</c> başlığı ile korunur; anahtar yapılandırılmamışsa uçlar 404 döner.
/// </summary>
[ApiController]
[Route("api/admin")]
[AllowAnonymous]
[AdminApiKey]
public class AdminController : ControllerBase
{
    private const int MaxReports = 200;

    private readonly SomineDbContext _dbContext;
    private readonly OnboardingDemoContentProvider _demoContent;
    private readonly TimeProvider _timeProvider;
    private readonly ILogger<AdminController> _logger;

    public AdminController(
        SomineDbContext dbContext,
        OnboardingDemoContentProvider demoContent,
        TimeProvider timeProvider,
        ILogger<AdminController> logger)
    {
        _dbContext = dbContext;
        _demoContent = demoContent;
        _timeProvider = timeProvider;
        _logger = logger;
    }

    [HttpGet("onboarding/demo-content")]
    public ActionResult<OnboardingDemoAdminContentDto> GetDemoContent() => Ok(_demoContent.GetForAdmin());

    [HttpPut("onboarding/demo-content")]
    public ActionResult<OnboardingDemoAdminContentDto> PutDemoContent([FromBody] OnboardingDemoAdminUpdateRequest request)
    {
        try
        {
            return Ok(_demoContent.Save(request.Items, _timeProvider.GetUtcNow()));
        }
        catch (OnboardingDemoContentValidationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
        catch (InvalidOperationException)
        {
            return Conflict(new { error = "Onboarding:DemoContentPath is not configured on the server." });
        }
    }

    [HttpGet("reports")]
    public async Task<ActionResult<IReadOnlyList<AdminReportDto>>> GetReports([FromQuery] string? status = "Open")
    {
        var query = _dbContext.ContentReports.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(status) && !string.Equals(status, "all", StringComparison.OrdinalIgnoreCase))
        {
            if (!Enum.TryParse<ReportStatus>(status, ignoreCase: true, out var parsed) || !Enum.IsDefined(parsed))
            {
                return BadRequest(new { error = "Unknown status." });
            }
            query = query.Where(r => r.Status == parsed);
        }

        var reports = await query
            .OrderBy(r => r.CreatedAt)
            .Take(MaxReports)
            .Select(r => new
            {
                r.Id, r.Reason, r.Note, r.Status, r.CreatedAt, r.ShareId, r.CategoryId,
                ReporterId = r.Reporter.Id, ReporterName = r.Reporter.DisplayName, ReporterUsername = r.Reporter.Username,
                ReportedId = r.ReportedUser.Id, ReportedName = r.ReportedUser.DisplayName, ReportedUsername = r.ReportedUser.Username
            })
            .ToListAsync(HttpContext.RequestAborted);

        var shareIds = reports.Where(r => r.ShareId != null).Select(r => r.ShareId!.Value).Distinct().ToList();
        var categoryIds = reports.Where(r => r.CategoryId != null).Select(r => r.CategoryId!.Value).Distinct().ToList();
        var shares = await _dbContext.CollectionShares.AsNoTracking()
            .Where(s => shareIds.Contains(s.Id))
            .Select(s => new { s.Id, s.CategoryName, s.Status })
            .ToDictionaryAsync(s => s.Id, HttpContext.RequestAborted);
        var categories = await _dbContext.Categories.AsNoTracking()
            .Where(c => categoryIds.Contains(c.Id))
            .Select(c => new { c.Id, c.Name })
            .ToDictionaryAsync(c => c.Id, c => c.Name, HttpContext.RequestAborted);

        return Ok(reports.Select(r =>
        {
            var share = r.ShareId is { } sid && shares.TryGetValue(sid, out var s) ? s : null;
            var name = r.CategoryId is { } cid && categories.TryGetValue(cid, out var n) ? n : share?.CategoryName;
            return new AdminReportDto(
                r.Id, r.Reason.ToString(), r.Note, r.Status.ToString(), r.CreatedAt,
                new AdminReportPersonDto(r.ReporterId, r.ReporterName, r.ReporterUsername),
                new AdminReportPersonDto(r.ReportedId, r.ReportedName, r.ReportedUsername),
                r.ShareId, r.CategoryId, name, share?.Status.ToString());
        }).ToList());
    }

    /// <summary>
    /// Şikâyeti kapatır. <c>remove_share</c> paylaşımı moderasyon e-postasındaki SQL ile aynı şekilde
    /// Rejected'a çeker (rejected_at = şimdi) ve şikâyeti ActionTaken yapar.
    /// </summary>
    [HttpPost("reports/{id:guid}/resolve")]
    public async Task<IActionResult> ResolveReport(Guid id, [FromBody] AdminResolveReportRequest request)
    {
        var action = request.Action?.Trim().ToLowerInvariant();
        if (action is not ("dismiss" or "remove_share" or "reviewed"))
        {
            return BadRequest(new { error = "action must be dismiss, remove_share or reviewed." });
        }

        var report = await _dbContext.ContentReports.FirstOrDefaultAsync(r => r.Id == id, HttpContext.RequestAborted);
        if (report == null) return NotFound(new { error = "Report not found" });
        if (report.Status != ReportStatus.Open) return Conflict(new { error = "Report is already resolved.", status = report.Status.ToString() });

        switch (action)
        {
            case "dismiss":
                report.Status = ReportStatus.Dismissed;
                break;
            case "reviewed":
                report.Status = ReportStatus.Reviewed;
                break;
            case "remove_share":
                if (report.ShareId == null) return BadRequest(new { error = "Report has no share to remove." });
                var share = await _dbContext.CollectionShares.FirstOrDefaultAsync(s => s.Id == report.ShareId, HttpContext.RequestAborted);
                if (share != null && share.Status != ShareStatus.Rejected)
                {
                    share.Status = ShareStatus.Rejected;
                    share.RejectedAt = _timeProvider.GetUtcNow().UtcDateTime;
                }
                report.Status = ReportStatus.ActionTaken;
                break;
        }

        await _dbContext.SaveChangesAsync(HttpContext.RequestAborted);
        _logger.LogInformation("Admin resolved report {ReportId} with {Action}.", report.Id, action);
        return Ok(new { id = report.Id, status = report.Status.ToString() });
    }
}
