using RestaurantApp.Domain.Models;

namespace RestaurantApp.UnitTests;

public sealed class OrderTests
{
    [Fact]
    public void AddItem_keeps_the_order_time_price_and_merges_matching_rows()
    {
        var item = AvailableItem(7, "Tiramisu", 8.50m);
        var order = Order.Create("ORD-TEST-001", 3);

        order.AddItem(item, 2, "No cocoa");
        item.Price = 12m;
        order.AddItem(item, 1, "No cocoa");

        var line = Assert.Single(order.OrderItems);
        Assert.Equal(3, line.Quantity);
        Assert.Equal(8.50m, line.UnitPrice);
        Assert.Equal(25.50m, order.TotalAmount);
    }

    [Fact]
    public void AddItem_rejects_an_unavailable_menu_item()
    {
        var item = AvailableItem(4, "Seasonal plate", 18m);
        item.IsAvailable = false;
        var order = Order.Create("ORD-TEST-002");

        var exception = Assert.Throws<InvalidOperationException>(() => order.AddItem(item, 1));

        Assert.Contains("not currently available", exception.Message);
    }

    [Fact]
    public void Order_follows_the_kitchen_status_sequence()
    {
        var order = Order.Create("ORD-TEST-003");

        order.MoveTo(OrderStatus.Preparing);
        order.MoveTo(OrderStatus.Ready);
        order.MoveTo(OrderStatus.Served);

        Assert.Equal(OrderStatus.Served, order.Status);
        Assert.Throws<InvalidOperationException>(() => order.MoveTo(OrderStatus.Cancelled));
    }

    [Fact]
    public void Cancel_records_the_reason_without_deleting_the_order()
    {
        var order = Order.Create("ORD-TEST-004");

        order.Cancel("Guest changed the order");

        Assert.Equal(OrderStatus.Cancelled, order.Status);
        Assert.Equal("Guest changed the order", order.CancellationReason);
        Assert.NotNull(order.CancelledAtUtc);
    }

    private static MenuItem AvailableItem(int id, string name, decimal price) => new()
    {
        Id = id,
        Name = name,
        Description = "A sufficiently descriptive menu item.",
        Price = price,
        CategoryId = 1,
        IsAvailable = true
    };
}
