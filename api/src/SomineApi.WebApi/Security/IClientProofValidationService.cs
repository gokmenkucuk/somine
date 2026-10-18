namespace SomineApi.WebApi.Security;

public interface IClientProofValidationService
{
    Task<ClientProofValidationResult> ValidateAsync(HttpContext httpContext, CancellationToken cancellationToken = default);
}
