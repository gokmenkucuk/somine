namespace SomineApi.WebApi.Options;

/// <summary>
/// Şikâyet (UGC report) e-posta uyarıları. <see cref="ReportEmail"/> ya da <see cref="Smtp"/>.Host boşsa
/// uyarı gönderilmez, yalnızca log'a yazılır. Prod'da env ile verilir:
/// <c>Moderation__ReportEmail</c>, <c>Moderation__Smtp__Host</c>, <c>Moderation__Smtp__Password</c> …
/// </summary>
public sealed class ModerationOptions
{
    public const string SectionName = "Moderation";

    public string ReportEmail { get; set; } = string.Empty;
    public SmtpSettings Smtp { get; set; } = new();

    public bool IsConfigured => !string.IsNullOrWhiteSpace(ReportEmail) && !string.IsNullOrWhiteSpace(Smtp.Host);

    public sealed class SmtpSettings
    {
        public string Host { get; set; } = string.Empty;
        public int Port { get; set; } = 587;
        public string User { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string From { get; set; } = "somine <destek@somineapp.com>";
    }
}
