using System.Collections.Concurrent;
using System.Net;
using System.Net.Http.Headers;

namespace SomineApi.Tests.Testing;

/// <summary>URL → yanıt eşlemesiyle çalışan sahte HTTP handler. Eşleşme yoksa 404.</summary>
public sealed class FakeImageHttpHandler : HttpMessageHandler
{
    private readonly ConcurrentDictionary<string, Func<HttpResponseMessage>> _responses = new();

    public ConcurrentQueue<Uri> Requests { get; } = new();

    public void RespondWith(string url, byte[] body, string contentType = "image/jpeg")
    {
        _responses[url] = () =>
        {
            var content = new ByteArrayContent(body);
            content.Headers.ContentType = MediaTypeHeaderValue.Parse(contentType);
            return new HttpResponseMessage(HttpStatusCode.OK) { Content = content };
        };
    }

    public void RespondWithStatus(string url, HttpStatusCode status)
        => _responses[url] = () => new HttpResponseMessage(status);

    public void RedirectTo(string url, string location, HttpStatusCode status = HttpStatusCode.Found)
        => _responses[url] = () =>
        {
            var response = new HttpResponseMessage(status);
            response.Headers.Location = new Uri(location, UriKind.RelativeOrAbsolute);
            return response;
        };

    public void Throw(string url, Exception exception)
        => _responses[url] = () => throw exception;

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        Requests.Enqueue(request.RequestUri!);
        var response = _responses.TryGetValue(request.RequestUri!.ToString(), out var factory)
            ? factory()
            : new HttpResponseMessage(HttpStatusCode.NotFound);
        return Task.FromResult(response);
    }

    // HttpClientFactory handler'ı ömrü dolunca dispose eder; sahte paylaşıldığı için yok say.
    protected override void Dispose(bool disposing)
    {
    }
}
