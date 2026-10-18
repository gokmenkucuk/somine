using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace SomineApi.WebApi.Hubs;

[Authorize]
public class NotificationsHub : Hub
{
    public override async Task OnConnectedAsync()
    {
        var userGroup = UserHubGroups.ResolveUserGroup(Context.User);
        if (userGroup != null)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, userGroup);
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userGroup = UserHubGroups.ResolveUserGroup(Context.User);
        if (userGroup != null)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, userGroup);
        }
        await base.OnDisconnectedAsync(exception);
    }
}
