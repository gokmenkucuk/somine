namespace SomineApi.Application;

public static class SubscriptionLimits
{
    public const int FreeMaxItems = 500;           // soft-delete edilmişler SAYILMAZ
    public const int FreeMaxCategories = 10;
    public const int FreeMaxActiveReminders = 3;   // yalnızca IsActive
    public const int FreeMaxActiveShares = 1;      // Pending + Accepted (Rejected sayılmaz)
}
