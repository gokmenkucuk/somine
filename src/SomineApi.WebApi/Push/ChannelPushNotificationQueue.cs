using System.Diagnostics.CodeAnalysis;
using System.Threading.Channels;
using Microsoft.Extensions.Options;
using SomineApi.WebApi.Options;

namespace SomineApi.WebApi.Push;

public sealed class ChannelPushNotificationQueue : IPushNotificationQueue
{
    private const int Capacity = 4096;

    private readonly Channel<PushNotificationRequest> _channel = Channel.CreateBounded<PushNotificationRequest>(
        new BoundedChannelOptions(Capacity)
        {
            SingleReader = true,
            SingleWriter = false,
            FullMode = BoundedChannelFullMode.DropWrite
        });

    private readonly IOptions<PushNotificationOptions> _options;
    private readonly ILogger<ChannelPushNotificationQueue> _logger;

    public ChannelPushNotificationQueue(IOptions<PushNotificationOptions> options, ILogger<ChannelPushNotificationQueue> logger)
    {
        _options = options;
        _logger = logger;
    }

    public bool Enqueue(PushNotificationRequest request)
    {
        try
        {
            if (!_options.Value.Enabled) return false;

            var written = _channel.Writer.TryWrite(request);
            if (!written)
            {
                _logger.LogWarning("Dropping push notification for user {UserId} because the push queue is full.", request.UserId);
            }

            return written;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to enqueue push notification for user {UserId}.", request.UserId);
            return false;
        }
    }

    public ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken)
        => _channel.Reader.WaitToReadAsync(cancellationToken);

    public bool TryRead([MaybeNullWhen(false)] out PushNotificationRequest request)
        => _channel.Reader.TryRead(out request);
}
