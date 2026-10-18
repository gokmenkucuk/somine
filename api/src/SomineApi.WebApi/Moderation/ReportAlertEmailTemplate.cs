using System.Globalization;
using System.Net;
using System.Text;
using SomineApi.Domain.Enums;

namespace SomineApi.WebApi.Moderation;

public sealed record ReportAlertPerson(Guid Id, string? DisplayName, string? Username, string? Email);

public sealed record ReportAlertItem(string? Title, string? Url, string? Note);

/// <summary>Şikâyet e-postasının içeriği; HTML ve düz metin aynı modelden üretilir.</summary>
public sealed record ReportAlertModel(
    Guid ReportId,
    ReportReason Reason,
    string? Note,
    DateTime CreatedAtUtc,
    ReportAlertPerson Reporter,
    ReportAlertPerson Reported,
    int PreviousReports,
    string? CategoryName,
    IReadOnlyList<ReportAlertItem> Items,
    bool HasMoreItems,
    Guid? ShareId);

/// <summary>
/// Moderatöre giden şikâyet e-postası. Tablo düzeni ve satır içi stiller kullanılır, çünkü e-posta
/// istemcileri CSS'in çoğunu yok sayar; logo mesajın içinde (cid) taşınır.
/// </summary>
public static class ReportAlertEmailTemplate
{
    public const string LogoContentId = "somine-logo";
    private const string Teal = "#0E9AA7";
    private const string Ink = "#111827";
    private const string Muted = "#646B78";
    private const string Line = "#E5E7EB";
    private const string Ground = "#F3F6F7";
    private const string Soft = "#F7FAFA";
    private const string Font = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif";
    private const string Mono = "ui-monospace,SFMono-Regular,Menlo,Consolas,monospace";

    private static readonly TimeZoneInfo Istanbul = FindIstanbul();

    public static string Subject(ReportAlertModel model) =>
        $"[somine Şikayet] {ReasonLabel(model.Reason)}: {Handle(model.Reported)}";

    public static string Html(ReportAlertModel model)
    {
        static string E(string? value) => WebUtility.HtmlEncode(value ?? string.Empty);
        var (badgeText, badgeBg) = ReasonBadge(model.Reason);
        var deadline = LocalTime(model.CreatedAtUtc.AddHours(24));
        var created = LocalTime(model.CreatedAtUtc);

        var html = new StringBuilder();
        html.Append($"""
<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<title>{E(Subject(model))}</title>
</head>
<body style="margin:0;padding:0;background:{Ground};font-family:{Font};">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">{E(ReasonLabel(model.Reason))} · {E(Handle(model.Reported))} · son inceleme {E(deadline)}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:{Ground};">
<tr><td align="center" style="padding:32px 16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:600px;">
<tr><td style="padding:0 8px 20px;">
<table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
<td style="vertical-align:middle;"><img src="cid:{LogoContentId}" width="44" height="44" alt="somine" style="display:block;border:0;width:44px;height:44px;border-radius:11px;"></td>
<td style="vertical-align:middle;padding-left:12px;font-size:15px;line-height:20px;color:{Ink};"><strong>somine</strong><br><span style="color:{Muted};font-size:13px;">İçerik moderasyonu</span></td>
</tr></table>
</td></tr>
<tr><td style="background:#FFFFFF;border-radius:20px;padding:32px 28px;border:1px solid {Line};">

<span style="display:inline-block;background:{badgeBg};color:#FFFFFF;font-size:12px;line-height:16px;font-weight:700;letter-spacing:0.4px;text-transform:uppercase;padding:5px 10px;border-radius:999px;">{E(badgeText)}</span>
<h1 style="margin:16px 0 8px;font-size:24px;line-height:30px;font-weight:700;letter-spacing:-0.3px;color:{Ink};">Yeni içerik şikâyeti</h1>
<p style="margin:0 0 20px;font-size:15px;line-height:22px;color:{Muted};">{E(created)} tarihinde gönderildi. App Store kuralı gereği <strong style="color:{Ink};">{E(deadline)}</strong> tarihine kadar incelenmeli.</p>
""");

        if (!string.IsNullOrWhiteSpace(model.Note))
        {
            html.Append($"""
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 20px;"><tr>
<td style="border-left:4px solid {Teal};background:{Soft};border-radius:0 12px 12px 0;padding:12px 16px;font-size:15px;line-height:22px;color:{Ink};">
<span style="display:block;font-size:12px;color:{Muted};margin-bottom:4px;">Şikâyet edenin notu</span>“{E(model.Note)}”</td>
</tr></table>
""");
        }

        html.Append($"""
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 20px;border:1px solid {Line};border-radius:14px;border-collapse:separate;">
{PersonRow("Şikâyet edilen", model.Reported, model.PreviousReports > 0 ? $"Daha önce {model.PreviousReports} kez şikâyet edildi" : "İlk şikâyet", model.PreviousReports > 0, top: true)}
{PersonRow("Şikâyet eden", model.Reporter, null, false, top: false)}
</table>

<p style="margin:0 0 8px;font-size:13px;line-height:18px;font-weight:700;letter-spacing:0.4px;text-transform:uppercase;color:{Muted};">Koleksiyon · {E(model.CategoryName ?? "silinmiş")}</p>
""");

        if (model.Items.Count == 0)
        {
            html.Append($"""<p style="margin:0 0 24px;font-size:15px;line-height:22px;color:{Muted};">Koleksiyonda içerik yok ya da koleksiyon silinmiş.</p>""");
        }
        else
        {
            html.Append($"""<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 24px;">""");
            foreach (var item in model.Items)
            {
                var title = string.IsNullOrWhiteSpace(item.Title) ? null : Shorten(item.Title.Trim(), 120);
                string body;
                if (!string.IsNullOrWhiteSpace(item.Url))
                {
                    var safeUrl = SafeHttpUrl(item.Url);
                    var host = Host(item.Url);
                    var label = E(title ?? host ?? item.Url);
                    body = safeUrl == null
                        ? $"""<span style="color:{Ink};">{label}</span><br><span style="font-size:13px;color:{Muted};word-break:break-all;">{E(Shorten(item.Url, 140))}</span>"""
                        : $"""<a href="{E(safeUrl)}" style="color:{Teal};text-decoration:none;font-weight:600;">{label}</a><br><span style="font-size:13px;color:{Muted};word-break:break-all;">{E(host ?? Shorten(item.Url, 140))}</span>""";
                }
                else
                {
                    body = $"""<span style="color:{Ink};">{E(title ?? "Not")}</span><br><span style="font-size:13px;color:{Muted};">{E(Shorten(item.Note?.Trim() ?? "(boş)", 200))}</span>""";
                }

                html.Append($"""<tr><td style="padding:10px 0;border-bottom:1px solid {Line};font-size:15px;line-height:21px;">{body}</td></tr>""");
            }

            if (model.HasMoreItems)
            {
                html.Append($"""<tr><td style="padding:10px 0;font-size:13px;color:{Muted};">… ve daha fazlası (ilk {model.Items.Count} içerik gösteriliyor)</td></tr>""");
            }

            html.Append("</table>");
        }

        html.Append($"""
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
<td style="background:{Soft};border:1px solid {Line};border-radius:14px;padding:16px 18px;">
<p style="margin:0 0 6px;font-size:15px;line-height:22px;font-weight:700;color:{Ink};">İnceleme sonrası</p>
<p style="margin:0 0 12px;font-size:14px;line-height:21px;color:{Muted};">Şikâyet eden kişi göndereni engellemiş olabilir; paylaşım onun kitaplığından zaten kalkmış olabilir. Prod veritabanında:</p>
""");
        if (model.ShareId != null)
        {
            html.Append(SqlBlock("İçerik uygunsuzsa paylaşımı kaldır", $"UPDATE collection_shares SET status = 'Rejected', rejected_at = NOW() WHERE id = '{model.ShareId}';"));
        }

        html.Append(SqlBlock("Şikâyeti kapat ('ActionTaken', 'Dismissed' ya da 'Reviewed')", $"UPDATE content_reports SET status = 'ActionTaken' WHERE id = '{model.ReportId}';"));
        html.Append($"""
</td></tr></table>

</td></tr>
<tr><td style="padding:20px 8px 0;font-size:12px;line-height:18px;color:{Muted};">
Şikâyet kimliği: <span style="font-family:{Mono};">{model.ReportId}</span><br>
Bu e-postayı somine API'si otomatik gönderdi; uygulamadaki şikâyetler 24 saat içinde incelenir.<br><br>
<strong style="color:{Ink};">somine</strong> · <a href="https://www.somineapp.com" style="color:{Muted};">somineapp.com</a> · <a href="mailto:destek@somineapp.com" style="color:{Muted};">destek@somineapp.com</a>
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>
""");
        return html.ToString();

        static string PersonRow(string label, ReportAlertPerson person, string? meta, bool warn, bool top)
        {
            var border = top ? string.Empty : $"border-top:1px solid {Line};";
            var name = string.IsNullOrWhiteSpace(person.DisplayName) ? "(adsız)" : person.DisplayName!;
            var username = string.IsNullOrWhiteSpace(person.Username) ? string.Empty : $" <span style=\"color:{Muted};font-weight:400;\">@{E(person.Username)}</span>";
            var metaHtml = meta == null
                ? string.Empty
                : $"""<br><span style="font-size:13px;color:{(warn ? "#B42318" : Muted)};font-weight:{(warn ? "600" : "400")};">{E(meta)}</span>""";
            return $"""
<tr><td style="padding:14px 16px;{border}">
<span style="display:block;font-size:12px;line-height:16px;color:{Muted};margin-bottom:4px;">{E(label)}</span>
<span style="font-size:16px;line-height:22px;font-weight:600;color:{Ink};">{E(name)}{username}</span><br>
<span style="font-size:14px;line-height:20px;color:{Ink};">{E(person.Email ?? "e-posta yok")}</span>{metaHtml}<br>
<span style="font-size:12px;line-height:18px;color:{Muted};font-family:{Mono};">{person.Id}</span>
</td></tr>
""";
        }

        static string SqlBlock(string caption, string sql) => $"""
<p style="margin:0 0 4px;font-size:13px;line-height:18px;color:{Muted};">{E(caption)}</p>
<div style="margin:0 0 12px;background:#FFFFFF;border:1px solid {Line};border-radius:10px;padding:10px 12px;font-family:{Mono};font-size:12px;line-height:18px;color:{Ink};word-break:break-all;">{E(sql)}</div>
""";
    }

    public static string Text(ReportAlertModel model)
    {
        var text = new StringBuilder();
        text.AppendLine("somine'da yeni bir içerik şikâyeti var. App Store kuralı gereği 24 saat içinde incelenmeli.");
        text.AppendLine();
        text.AppendLine($"Sebep:          {ReasonLabel(model.Reason)}");
        if (!string.IsNullOrWhiteSpace(model.Note))
        {
            text.AppendLine($"Not:            {model.Note}");
        }

        text.AppendLine($"Tarih:          {LocalTime(model.CreatedAtUtc)}");
        text.AppendLine($"Son inceleme:   {LocalTime(model.CreatedAtUtc.AddHours(24))}");
        text.AppendLine($"Şikâyet eden:   {PersonLine(model.Reporter)}");
        text.AppendLine($"Şikâyet edilen: {PersonLine(model.Reported)}");
        text.AppendLine($"Bu kişi hakkında önceki şikâyet sayısı: {model.PreviousReports}");
        text.AppendLine($"Koleksiyon:     {model.CategoryName ?? "(silinmiş)"}");
        text.AppendLine();

        if (model.Items.Count == 0)
        {
            text.AppendLine("Koleksiyonda içerik yok ya da koleksiyon silinmiş.");
        }
        else
        {
            text.AppendLine("Koleksiyondaki içerikler (en yeniler):");
            foreach (var item in model.Items)
            {
                var title = string.IsNullOrWhiteSpace(item.Title) ? null : Shorten(item.Title.Trim(), 120);
                var body = item.Url ?? (string.IsNullOrWhiteSpace(item.Note) ? "(boş)" : Shorten(item.Note.Trim(), 200));
                text.AppendLine(title == null ? $"- {body}" : $"- {title}\n  {body}");
            }

            if (model.HasMoreItems)
            {
                text.AppendLine("- … ve daha fazlası");
            }
        }

        text.AppendLine();
        text.AppendLine("Şikâyet eden kişi göndereni engellemiş olabilir; paylaşım onun kitaplığından zaten kalkmış olabilir.");
        text.AppendLine();
        text.AppendLine("İnceleme sonrası (prod veritabanında):");
        if (model.ShareId != null)
        {
            text.AppendLine("  -- İçerik uygunsuzsa paylaşımı kaldır:");
            text.AppendLine($"  UPDATE collection_shares SET status = 'Rejected', rejected_at = NOW() WHERE id = '{model.ShareId}';");
        }

        text.AppendLine("  -- Şikâyeti kapat ('ActionTaken', 'Dismissed' ya da 'Reviewed'):");
        text.AppendLine($"  UPDATE content_reports SET status = 'ActionTaken' WHERE id = '{model.ReportId}';");
        text.AppendLine();
        text.AppendLine($"Şikâyet kimliği: {model.ReportId}");
        return text.ToString();

        static string PersonLine(ReportAlertPerson person)
        {
            var name = string.Join(" ", new[] { person.DisplayName, person.Username == null ? null : "@" + person.Username }
                .Where(part => !string.IsNullOrWhiteSpace(part)));
            return $"{(name.Length == 0 ? "(adsız)" : name)} <{person.Email ?? "e-posta yok"}> · {person.Id}";
        }
    }

    public static byte[] Logo { get; } = LoadLogo();

    public static string ReasonLabel(ReportReason reason) => reason switch
    {
        ReportReason.Spam => "Spam",
        ReportReason.Inappropriate => "Uygunsuz içerik",
        ReportReason.Harassment => "Taciz",
        _ => "Diğer"
    };

    private static (string Text, string Background) ReasonBadge(ReportReason reason) => reason switch
    {
        ReportReason.Harassment => ("Taciz", "#B42318"),
        ReportReason.Inappropriate => ("Uygunsuz içerik", "#C2410C"),
        ReportReason.Spam => ("Spam", "#8A5A00"),
        _ => ("Diğer", "#4B5563")
    };

    private static string Handle(ReportAlertPerson person) =>
        person.Username ?? person.DisplayName ?? "kullanıcı";

    private static string LocalTime(DateTime utc)
    {
        var local = TimeZoneInfo.ConvertTimeFromUtc(DateTime.SpecifyKind(utc, DateTimeKind.Utc), Istanbul);
        return local.ToString("d MMMM yyyy HH:mm", CultureInfo.GetCultureInfo("tr-TR")) + " (TSİ)";
    }

    // Kullanıcı içeriğinden gelen linkler yalnızca http(s) ise tıklanabilir yapılır.
    private static string? SafeHttpUrl(string url) =>
        Uri.TryCreate(url.Trim(), UriKind.Absolute, out var uri) && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps)
            ? uri.AbsoluteUri
            : null;

    private static string? Host(string url) =>
        Uri.TryCreate(url.Trim(), UriKind.Absolute, out var uri)
            ? (uri.Host.StartsWith("www.", StringComparison.OrdinalIgnoreCase) ? uri.Host[4..] : uri.Host)
            : null;

    private static string Shorten(string value, int max) => value.Length <= max ? value : value[..max] + "…";

    private static TimeZoneInfo FindIstanbul()
    {
        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById("Europe/Istanbul");
        }
        catch (Exception ex) when (ex is TimeZoneNotFoundException or InvalidTimeZoneException)
        {
            return TimeZoneInfo.CreateCustomTimeZone("TRT", TimeSpan.FromHours(3), "TRT", "TRT");
        }
    }

    private static byte[] LoadLogo()
    {
        using var stream = typeof(ReportAlertEmailTemplate).Assembly.GetManifestResourceStream("SomineApi.ModerationEmailLogo")
            ?? throw new InvalidOperationException("Moderation email logo resource is missing.");
        using var copy = new MemoryStream();
        stream.CopyTo(copy);
        return copy.ToArray();
    }
}
