using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace SomineApi.WebApi.Security;

public class ClientProofAuthorizationFilter : IAsyncAuthorizationFilter
{
    private readonly IClientProofValidationService _clientProofValidationService;

    public ClientProofAuthorizationFilter(IClientProofValidationService clientProofValidationService)
    {
        _clientProofValidationService = clientProofValidationService;
    }

    public async Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var result = await _clientProofValidationService.ValidateAsync(context.HttpContext, context.HttpContext.RequestAborted);
        if (!result.IsValid)
        {
            context.Result = new UnauthorizedObjectResult(new { error = result.Error });
            return;
        }

        if (!string.IsNullOrWhiteSpace(result.ClientId))
        {
            context.HttpContext.Items[HttpContextItemKeys.VerifiedClientId] = result.ClientId;
        }

        if (!string.IsNullOrWhiteSpace(result.Platform))
        {
            context.HttpContext.Items[HttpContextItemKeys.VerifiedClientPlatform] = result.Platform;
        }
    }
}
