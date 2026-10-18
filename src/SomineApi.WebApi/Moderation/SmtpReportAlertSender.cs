using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;
using SomineApi.WebApi.Options;

namespace SomineApi.WebApi.Moderation;

/// <summary>Şikâyet uyarısını SMTP (STARTTLS ya da 465'te SSL) ile HTML + düz metin olarak gönderir.</summary>
public sealed class SmtpReportAlertSender : IReportAlertSender
{
    private readonly IOptions<ModerationOptions> _options;
    private readonly ILogger<SmtpReportAlertSender> _logger;

    public SmtpReportAlertSender(IOptions<ModerationOptions> options, ILogger<SmtpReportAlertSender> logger)
    {
        _options = options;
        _logger = logger;
    }

    public async Task<bool> SendAsync(ReportAlertEmail email, CancellationToken cancellationToken)
    {
        var smtp = _options.Value.Smtp;

        var message = new MimeMessage();
        message.From.Add(MailboxAddress.Parse(smtp.From));
        message.To.Add(MailboxAddress.Parse(email.To));
        message.Subject = email.Subject;
        if (email.HtmlBody == null)
        {
            message.Body = new TextPart("plain") { Text = email.TextBody };
        }
        else
        {
            var body = new BodyBuilder { TextBody = email.TextBody };
            var logo = body.LinkedResources.Add("somine-logo.png", ReportAlertEmailTemplate.Logo, new ContentType("image", "png"));
            logo.ContentId = ReportAlertEmailTemplate.LogoContentId;
            body.HtmlBody = email.HtmlBody;
            message.Body = body.ToMessageBody();
        }

        try
        {
            using var client = new SmtpClient { Timeout = 15_000 };
            var security = smtp.Port == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTls;
            await client.ConnectAsync(smtp.Host, smtp.Port, security, cancellationToken);
            if (!string.IsNullOrEmpty(smtp.User))
            {
                await client.AuthenticateAsync(smtp.User, smtp.Password, cancellationToken);
            }

            await client.SendAsync(message, cancellationToken);
            await client.DisconnectAsync(true, cancellationToken);
            return true;
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogError(ex, "Report alert email '{Subject}' could not be sent.", email.Subject);
            return false;
        }
    }
}
