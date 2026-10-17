using System.Collections.Concurrent;
using SomineApi.Application.Interfaces;

namespace SomineApi.Tests.Testing;

/// <summary>FCM'e gitmeden gönderilen push mesajlarını kaydeden test ikizi.</summary>
public sealed class FakePushNotificationSender : IPushNotificationSender
{
    private readonly ConcurrentQueue<PushMessage> _sent = new();
    private readonly SemaphoreSlim _signal = new(0);

    public bool IsConfigured { get; set; } = true;

    /// <summary>FCM'in "unregistered" diyeceği token'lar.</summary>
    public HashSet<string> InvalidTokens { get; } = new(StringComparer.Ordinal);

    /// <summary>Doluysa gönderim bu istisnayı fırlatır (FCM kesintisi benzetimi).</summary>
    public Exception? ThrowOnSend { get; set; }

    public IReadOnlyCollection<PushMessage> Sent => _sent.ToArray();

    public Task<PushSendResult> SendAsync(IReadOnlyList<PushMessage> messages, CancellationToken cancellationToken = default)
    {
        try
        {
            if (ThrowOnSend != null) throw ThrowOnSend;

            foreach (var message in messages) _sent.Enqueue(message);

            var invalid = messages.Select(m => m.Token).Where(InvalidTokens.Contains).ToList();
            return Task.FromResult(new PushSendResult(messages.Count - invalid.Count, invalid));
        }
        finally
        {
            _signal.Release();
        }
    }

    /// <summary>Arka plan servisi bir gönderim turunu tamamlayana kadar bekler.</summary>
    public async Task WaitForSendAsync(TimeSpan timeout)
    {
        if (!await _signal.WaitAsync(timeout))
        {
            throw new TimeoutException("No push notification was sent.");
        }
    }
}
