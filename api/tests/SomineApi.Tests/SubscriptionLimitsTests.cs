using SomineApi.Application;

namespace SomineApi.Tests;

public class SubscriptionLimitsTests
{
    [Fact]
    public void FreeMaxItems_Is500()
    {
        Assert.Equal(500, SubscriptionLimits.FreeMaxItems);
    }

    [Fact]
    public void FreeMaxCategories_Is10()
    {
        Assert.Equal(10, SubscriptionLimits.FreeMaxCategories);
    }

    [Fact]
    public void FreeMaxActiveReminders_Is3()
    {
        Assert.Equal(3, SubscriptionLimits.FreeMaxActiveReminders);
    }

    [Fact]
    public void FreeMaxActiveShares_Is1()
    {
        Assert.Equal(1, SubscriptionLimits.FreeMaxActiveShares);
    }

    [Theory]
    [InlineData(499, false)]
    [InlineData(500, true)]
    [InlineData(501, true)]
    public void ItemLimit_ReachedWhenCurrentGreaterOrEqualToLimit(int current, bool expectedReached)
    {
        var reached = current >= SubscriptionLimits.FreeMaxItems;

        Assert.Equal(expectedReached, reached);
    }

    [Theory]
    [InlineData(9, false)]
    [InlineData(10, true)]
    public void CategoryLimit_ReachedWhenCurrentGreaterOrEqualToLimit(int current, bool expectedReached)
    {
        var reached = current >= SubscriptionLimits.FreeMaxCategories;

        Assert.Equal(expectedReached, reached);
    }

    [Theory]
    [InlineData(2, false)]
    [InlineData(3, true)]
    public void ReminderLimit_ReachedWhenCurrentGreaterOrEqualToLimit(int current, bool expectedReached)
    {
        var reached = current >= SubscriptionLimits.FreeMaxActiveReminders;

        Assert.Equal(expectedReached, reached);
    }

    [Theory]
    [InlineData(0, false)]
    [InlineData(1, true)]
    public void ShareLimit_ReachedWhenCurrentGreaterOrEqualToLimit(int current, bool expectedReached)
    {
        var reached = current >= SubscriptionLimits.FreeMaxActiveShares;

        Assert.Equal(expectedReached, reached);
    }

    [Theory]
    [InlineData(498, 1, false)] // 498 + 1 = 499 -> ok
    [InlineData(498, 2, false)] // 498 + 2 = 500 -> ok (== limit, not exceeding)
    [InlineData(498, 3, true)]  // 498 + 3 = 501 -> exceeds limit
    [InlineData(500, 1, true)]  // already at limit, any copy exceeds
    public void CopyItems_ExceedsLimitWhenCurrentPlusCountGreaterThanLimit(int current, int copyCount, bool expectedExceeds)
    {
        var exceeds = current + copyCount > SubscriptionLimits.FreeMaxItems;

        Assert.Equal(expectedExceeds, exceeds);
    }
}
