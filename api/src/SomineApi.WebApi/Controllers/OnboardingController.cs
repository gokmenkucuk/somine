using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SomineApi.WebApi.Onboarding;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/onboarding")]
[Authorize]
public class OnboardingController : ControllerBase
{
    private readonly OnboardingDemoContentProvider _demoContent;

    public OnboardingController(OnboardingDemoContentProvider demoContent)
    {
        _demoContent = demoContent;
    }

    // Kayıtta eklenecek örnek içerik. Uygulama alamazsa kendi içindeki listeye düşer.
    [HttpGet("demo-content")]
    public ActionResult<OnboardingDemoContentDto> GetDemoContent() => Ok(_demoContent.Get());
}
