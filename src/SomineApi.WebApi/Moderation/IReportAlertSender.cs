namespace SomineApi.WebApi.Moderation;

/// <summary>Moderatöre giden tek bir şikâyet uyarısı.</summary>
public sealed record ReportAlertEmail(string To, string Subject, string TextBody);

public interface IReportAlertSender
{
    Task<bool> SendAsync(ReportAlertEmail email, CancellationToken cancellationToken);
}
