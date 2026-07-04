using Microsoft.AspNetCore.Mvc;

namespace SomineApi.WebApi.Security;

public class RequireClientProofAttribute : TypeFilterAttribute
{
    public RequireClientProofAttribute() : base(typeof(ClientProofAuthorizationFilter))
    {
    }
}
