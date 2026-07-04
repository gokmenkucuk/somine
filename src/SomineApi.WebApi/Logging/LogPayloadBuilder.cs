using System.Diagnostics;
using System.Security.Claims;
using System.Text.Json;
using SomineApi.Domain.Entities;

namespace SomineApi.WebApi.Logging;

public static class LogPayloadBuilder
{
    public const string RequestLogIdItemKey = "__somine_request_log_id";

    private static readonly HashSet<string> AllowedHeaderNames = new(StringComparer.OrdinalIgnoreCase)
    {
        "User-Agent",
        "Content-Type",
        "Content-Length",
        "X-SoMine-Client-Id",
        "X-Request-Id",
        "X-Forwarded-For",
        "X-Real-IP"
    };

    private static readonly HashSet<string> SensitiveKeys = new(StringComparer.OrdinalIgnoreCase)
    {
        "access_token",
        "refresh_token",
        "token",
        "authorization",
        "password",
        "secret",
        "signature",
        "idToken",
        "refreshToken"
    };

    public static RequestLog BuildRequestLog(HttpContext context, long durationMs)
    {
        return new RequestLog
        {
            Id = GetOrCreateRequestLogId(context),
            TraceId = Activity.Current?.Id ?? context.TraceIdentifier,
            RequestId = context.TraceIdentifier,
            UserId = TryGetUserId(context.User),
            Method = context.Request.Method,
            Path = context.Request.Path.Value ?? string.Empty,
            QueryString = BuildSanitizedQueryString(context.Request.Query),
            RouteTemplate = (context.GetEndpoint() as Microsoft.AspNetCore.Routing.RouteEndpoint)?.RoutePattern.RawText,
            ControllerName = context.GetRouteValue("controller")?.ToString(),
            ActionName = context.GetRouteValue("action")?.ToString(),
            StatusCode = context.Response.StatusCode,
            DurationMs = durationMs,
            IpAddress = context.Connection.RemoteIpAddress?.ToString(),
            UserAgent = Truncate(context.Request.Headers.UserAgent.ToString(), 2048),
            ClientId = Truncate(context.Request.Headers["X-SoMine-Client-Id"].ToString(), 128),
            Source = ResolveSource(context),
            RequestSizeBytes = context.Request.ContentLength,
            ResponseSizeBytes = context.Response.ContentLength,
            RequestHeadersJson = BuildSanitizedHeadersJson(context.Request.Headers),
            RequestBodyPreview = null,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    public static ExceptionLog BuildExceptionLog(HttpContext context, Exception exception, bool isHandled)
    {
        return new ExceptionLog
        {
            Id = Guid.NewGuid(),
            RequestLogId = TryGetRequestLogId(context),
            TraceId = Activity.Current?.Id ?? context.TraceIdentifier,
            UserId = TryGetUserId(context.User),
            ExceptionType = exception.GetType().FullName ?? exception.GetType().Name,
            Message = Truncate(exception.Message, 4000) ?? string.Empty,
            StackTrace = exception.StackTrace,
            InnerExceptionJson = BuildInnerExceptionJson(exception.InnerException),
            Source = ResolveSource(context),
            Path = context.Request.Path.Value,
            Method = context.Request.Method,
            QueryString = BuildSanitizedQueryString(context.Request.Query),
            IpAddress = context.Connection.RemoteIpAddress?.ToString(),
            UserAgent = Truncate(context.Request.Headers.UserAgent.ToString(), 2048),
            ClientId = Truncate(context.Request.Headers["X-SoMine-Client-Id"].ToString(), 128),
            IsHandled = isHandled,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    public static Guid GetOrCreateRequestLogId(HttpContext context)
    {
        if (context.Items.TryGetValue(RequestLogIdItemKey, out var existingValue) &&
            existingValue is Guid existingId)
        {
            return existingId;
        }

        var requestLogId = Guid.NewGuid();
        context.Items[RequestLogIdItemKey] = requestLogId;
        return requestLogId;
    }

    public static Guid? TryGetRequestLogId(HttpContext context)
    {
        if (context.Items.TryGetValue(RequestLogIdItemKey, out var existingValue) &&
            existingValue is Guid existingId)
        {
            return existingId;
        }

        return null;
    }

    private static Guid? TryGetUserId(ClaimsPrincipal? user)
    {
        var claim = user?.FindFirst(ClaimTypes.NameIdentifier) ?? user?.FindFirst("sub");
        return Guid.TryParse(claim?.Value, out var userId) ? userId : null;
    }

    private static string? BuildSanitizedHeadersJson(IHeaderDictionary headers)
    {
        var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        foreach (var header in headers)
        {
            if (!AllowedHeaderNames.Contains(header.Key))
            {
                continue;
            }

            values[header.Key] = Truncate(header.Value.ToString(), 2048) ?? string.Empty;
        }

        return values.Count == 0 ? null : JsonSerializer.Serialize(values);
    }

    private static string? BuildSanitizedQueryString(IQueryCollection query)
    {
        if (query.Count == 0)
        {
            return null;
        }

        var sanitized = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);
        foreach (var item in query)
        {
            sanitized[item.Key] = SensitiveKeys.Contains(item.Key)
                ? "***"
                : Truncate(item.Value.ToString(), 512);
        }

        return JsonSerializer.Serialize(sanitized);
    }

    private static string? BuildInnerExceptionJson(Exception? innerException)
    {
        if (innerException == null)
        {
            return null;
        }

        var payload = new Dictionary<string, object?>
        {
            ["type"] = innerException.GetType().FullName ?? innerException.GetType().Name,
            ["message"] = Truncate(innerException.Message, 4000),
            ["inner"] = BuildInnerExceptionJson(innerException.InnerException)
        };

        return JsonSerializer.Serialize(payload);
    }

    private static string ResolveSource(HttpContext context)
    {
        var clientId = context.Request.Headers["X-SoMine-Client-Id"].ToString();
        if (clientId.Contains("mobile", StringComparison.OrdinalIgnoreCase))
        {
            return "mobile";
        }

        if (clientId.Contains("web", StringComparison.OrdinalIgnoreCase))
        {
            return "web";
        }

        var userAgent = context.Request.Headers.UserAgent.ToString();
        if (userAgent.Contains("CFNetwork", StringComparison.OrdinalIgnoreCase) ||
            userAgent.Contains("iPhone", StringComparison.OrdinalIgnoreCase) ||
            userAgent.Contains("Android", StringComparison.OrdinalIgnoreCase))
        {
            return "mobile";
        }

        if (userAgent.Contains("Mozilla", StringComparison.OrdinalIgnoreCase) ||
            userAgent.Contains("Chrome", StringComparison.OrdinalIgnoreCase) ||
            userAgent.Contains("Safari", StringComparison.OrdinalIgnoreCase))
        {
            return "web";
        }

        return "unknown";
    }

    private static string? Truncate(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Length <= maxLength ? value : value[..maxLength];
    }
}
