namespace RestaurantApp.Domain.Models;

public enum OrderStatus
{
    Pending = 1,
    Preparing = 2,
    Ready = 3,
    Served = 4,
    Cancelled = 5
}

public static class OrderStatusExtensions
{
    public static bool CanTransitionTo(this OrderStatus current, OrderStatus next) =>
        (current, next) switch
        {
            (OrderStatus.Pending, OrderStatus.Preparing) => true,
            (OrderStatus.Preparing, OrderStatus.Ready) => true,
            (OrderStatus.Ready, OrderStatus.Served) => true,
            (_, OrderStatus.Cancelled) when current is not OrderStatus.Served and not OrderStatus.Cancelled => true,
            _ => false
        };
}
