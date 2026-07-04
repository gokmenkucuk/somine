using System.Net.Http.Headers;
using Microsoft.Extensions.DependencyInjection;
using SomineApi.Application.Interfaces;

namespace SomineApi.Tests.Testing;

public static class IntegrationTestClientExtensions
{
    public static HttpClient CreateAuthenticatedClient(
        this SomineApiWebApplicationFactory factory,
        Guid userId,
        string email = "user@somine.test",
        string firebaseUid = "firebase-user")
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);

        using var scope = factory.Services.CreateScope();
        var jwtService = scope.ServiceProvider.GetRequiredService<IJwtService>();
        var token = jwtService.GenerateAccessToken(userId, email, firebaseUid, Guid.NewGuid());
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        return client;
    }
}
