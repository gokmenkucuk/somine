using FirebaseAdmin.Messaging;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SomineApi.Application.Interfaces;

namespace SomineApi.Infrastructure.Services;

/// <summary>
/// Firebase Cloud Messaging üzerinden push gönderir (iOS'ta FCM → APNs).
/// </summary>
/// <remarks>
/// <see cref="FirebaseAuthService"/> ile aynı varsayılan <c>FirebaseApp</c>'i kullanır; ikinci bir
/// uygulama oluşturmaz. Kimlik bilgisi yoksa servis "yapılandırılmamış" sayılır ve gönderim
/// sessizce atlanır (uyarı bir kez loglanır). Singleton olarak kaydedilmelidir.
/// </remarks>
public sealed class FcmPushNotificationSender : IPushNotificationSender
{
    // FCM v1 SendEach çağrısı başına azami mesaj sayısı.
    private const int MaxBatchSize = 500;

    private readonly ILogger<FcmPushNotificationSender> _logger;
    private readonly Lazy<FirebaseMessaging?> _messaging;

    public FcmPushNotificationSender(IConfiguration configuration, ILogger<FcmPushNotificationSender> logger)
    {
        _logger = logger;
        _messaging = new Lazy<FirebaseMessaging?>(() => CreateMessaging(configuration), LazyThreadSafetyMode.ExecutionAndPublication);
    }

    public bool IsConfigured => _messaging.Value != null;

    public async Task<PushSendResult> SendAsync(IReadOnlyList<PushMessage> messages, CancellationToken cancellationToken = default)
    {
        var messaging = _messaging.Value;
        if (messaging == null || messages.Count == 0) return PushSendResult.Empty;

        var successCount = 0;
        var invalidTokens = new List<string>();

        foreach (var chunk in messages.Chunk(MaxBatchSize))
        {
            var fcmMessages = chunk.Select(ToFcmMessage).ToList();
            var response = await messaging.SendEachAsync(fcmMessages, cancellationToken);
            successCount += response.SuccessCount;

            for (var i = 0; i < response.Responses.Count; i++)
            {
                var result = response.Responses[i];
                if (result.IsSuccess) continue;

                if (IsInvalidTokenError(result.Exception))
                {
                    invalidTokens.Add(chunk[i].Token);
                }
                else
                {
                    _logger.LogWarning(result.Exception,
                        "FCM send failed. ErrorCode={ErrorCode}", result.Exception?.MessagingErrorCode);
                }
            }
        }

        return new PushSendResult(successCount, invalidTokens);
    }

    private static Message ToFcmMessage(PushMessage message) => new()
    {
        Token = message.Token,
        Notification = new Notification
        {
            Title = message.Title,
            Body = message.Body
        },
        Data = message.Data,
        Apns = new ApnsConfig
        {
            Aps = new Aps
            {
                Sound = "default"
            }
        },
        Android = new AndroidConfig
        {
            Priority = Priority.High
        }
    };

    /// <summary>
    /// Token'ın kalıcı olarak geçersiz olduğunu (uygulama silinmiş, token yenilenmiş, başka projeye
    /// ait) gösteren hatalar. Geçici hatalarda (kota, sunucu) token silinmez.
    /// </summary>
    private static bool IsInvalidTokenError(FirebaseMessagingException? exception)
    {
        if (exception == null) return false;

        return exception.MessagingErrorCode switch
        {
            MessagingErrorCode.Unregistered => true,
            MessagingErrorCode.SenderIdMismatch => true,
            // INVALID_ARGUMENT yük hatası için de dönebilir; yalnız token'dan kaynaklıysa sil.
            MessagingErrorCode.InvalidArgument =>
                exception.Message.Contains("registration token", StringComparison.OrdinalIgnoreCase),
            _ => false
        };
    }

    private FirebaseMessaging? CreateMessaging(IConfiguration configuration)
    {
        try
        {
            return FirebaseMessaging.GetMessaging(FirebaseAppProvider.GetOrCreateDefault(configuration));
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Firebase messaging is not configured; push notifications will be skipped.");
            return null;
        }
    }
}
