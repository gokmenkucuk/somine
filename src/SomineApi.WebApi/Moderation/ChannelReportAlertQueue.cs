using System.Threading.Channels;

namespace SomineApi.WebApi.Moderation;

public sealed class ChannelReportAlertQueue : IReportAlertQueue
{
    private const int Capacity = 1024;

    private readonly Channel<Guid> _channel = Channel.CreateBounded<Guid>(
        new BoundedChannelOptions(Capacity)
        {
            SingleReader = true,
            SingleWriter = false,
            FullMode = BoundedChannelFullMode.DropWrite
        });

    private readonly ILogger<ChannelReportAlertQueue> _logger;

    public ChannelReportAlertQueue(ILogger<ChannelReportAlertQueue> logger)
    {
        _logger = logger;
    }

    public bool Enqueue(Guid reportId)
    {
        var written = _channel.Writer.TryWrite(reportId);
        if (!written)
        {
            // Şikâyet kaydı DB'de duruyor; yalnızca e-posta uyarısı düşer.
            _logger.LogWarning("Dropping email alert for report {ReportId} because the alert queue is full.", reportId);
        }

        return written;
    }

    public ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken)
        => _channel.Reader.WaitToReadAsync(cancellationToken);

    public bool TryRead(out Guid reportId)
        => _channel.Reader.TryRead(out reportId);
}
