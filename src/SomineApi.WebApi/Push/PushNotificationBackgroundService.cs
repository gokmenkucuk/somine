using Microsoft.EntityFrameworkCore;
using SomineApi.Application.Interfaces;
using SomineApi.Infrastructure.Data;

namespace SomineApi.WebApi.Push;

/// <summary>
/// <see cref="IPushNotificationQueue"/>'yu tüketir: alıcının cihaz token'larını bulur, metni her
/// cihazın diline göre kurar, FCM ile gönderir ve FCM'in geçersiz dediği token'ları siler.
/// </summary>
/// <remarks>
/// Her hata yakalanıp loglanır; push gönderimi hiçbir HTTP isteğini veya bildirim kaydını etkilemez.
/// Gönderici yapılandırılmamışsa (Firebase kimlik bilgisi yok) kuyruk boşaltılır ve atlanır.
/// </remarks>
public sealed class PushNotificationBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IPushNotificationQueue _queue;
    private readonly IPushNotificationSender _sender;
    private readonly ILogger<PushNotificationBackgroundService> _logger;
    private bool _loggedNotConfigured;

    public PushNotificationBackgroundService(
        IServiceScopeFactory scopeFactory,
        IPushNotificationQueue queue,
        IPushNotificationSender sender,
        ILogger<PushNotificationBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _queue = queue;
        _sender = sender;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (await _queue.WaitToReadAsync(stoppingToken))
        {
            while (_queue.TryRead(out var request))
            {
                try
                {
                    await ProcessAsync(request, stoppingToken);
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Push notification failed. UserId={UserId} Type={Type}", request.UserId, request.Type);
                }
            }
        }
    }

    /// <summary>Tek bir isteği işler. Doğrudan çağrılabilir (test edilebilirlik için public).</summary>
    public async Task ProcessAsync(PushNotificationRequest request, CancellationToken cancellationToken = default)
    {
        if (!_sender.IsConfigured)
        {
            if (!_loggedNotConfigured)
            {
                _loggedNotConfigured = true;
                _logger.LogInformation("Push sender is not configured; skipping push notifications.");
            }
            return;
        }

        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();

        var tokens = await dbContext.DeviceTokens
            .AsNoTracking()
            .Where(t => t.UserId == request.UserId)
            .Select(t => new { t.Token, t.Locale })
            .ToListAsync(cancellationToken);

        if (tokens.Count == 0) return;

        var messages = new List<PushMessage>(tokens.Count);
        foreach (var token in tokens)
        {
            var text = PushNotificationTexts.Build(request, token.Locale);
            if (text is null) return; // Desteklenmeyen tür: push gönderilmez.

            messages.Add(new PushMessage(token.Token, text.Value.Title, text.Value.Body, request.Data));
        }

        var result = await _sender.SendAsync(messages, cancellationToken);

        if (result.InvalidTokens.Count > 0)
        {
            var invalid = result.InvalidTokens.ToList();
            var removed = await dbContext.DeviceTokens
                .Where(t => invalid.Contains(t.Token))
                .ExecuteDeleteAsync(cancellationToken);

            _logger.LogInformation("Removed {Count} invalid device token(s) for user {UserId}.", removed, request.UserId);
        }
    }
}
