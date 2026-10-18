namespace SomineApi.WebApi.Moderation;

/// <summary>Moderatöre giden tek bir şikâyet uyarısı. HtmlBody varsa e-posta HTML + düz metin olarak gider.</summary>
public sealed record ReportAlertEmail(string To, string Subject, string TextBody, string? HtmlBody = null);

public interface IReportAlertSender
{
    Task<bool> SendAsync(ReportAlertEmail email, CancellationToken cancellationToken);
}
