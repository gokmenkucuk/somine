using System.Collections.Concurrent;
using SomineApi.WebApi.Moderation;

namespace SomineApi.Tests.Testing;

public sealed class FakeReportAlertSender : IReportAlertSender
{
    private readonly ConcurrentQueue<ReportAlertEmail> _sent = new();
    private readonly SemaphoreSlim _signal = new(0);

    public IReadOnlyCollection<ReportAlertEmail> Sent => _sent.ToArray();

    public Task<bool> SendAsync(ReportAlertEmail email, CancellationToken cancellationToken)
    {
        _sent.Enqueue(email);
        _signal.Release();
        return Task.FromResult(true);
    }

    // Arka plan servisi e-postayı gönderene kadar bekler.
    public async Task<ReportAlertEmail> WaitForEmailAsync(TimeSpan timeout)
    {
        if (!await _signal.WaitAsync(timeout))
        {
            throw new TimeoutException("No report alert email was sent.");
        }

        return _sent.Last();
    }
}
