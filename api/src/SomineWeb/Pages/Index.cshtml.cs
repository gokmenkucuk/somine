using Microsoft.AspNetCore.Mvc.RazorPages;

namespace SomineWeb.Pages;

public class IndexModel : PageModel
{
    private readonly IConfiguration _configuration;

    public IndexModel(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public string AppStoreUrl => _configuration["AppStoreUrl"] ?? "https://apps.apple.com/app/somine";

    public void OnGet()
    {
    }
}
