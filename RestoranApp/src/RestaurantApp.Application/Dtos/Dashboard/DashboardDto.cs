namespace RestaurantApp.Application.Dtos.Dashboard;

public sealed class DashboardDto
{
    public decimal TodayRevenue { get; set; }
    public int TodayOrderCount { get; set; }
    public int ActiveOrderCount { get; set; }
    public decimal AverageTicket { get; set; }
    public int AvailableMenuItemCount { get; set; }
    public int OccupiedTableCount { get; set; }
    public IReadOnlyList<DashboardOrderDto> RecentOrders { get; set; } = [];
    public IReadOnlyList<TopSellingItemDto> TopSellingItems { get; set; } = [];
}

public sealed class DashboardOrderDto
{
    public int Id { get; set; }
    public string Number { get; set; } = string.Empty;
    public string? TableNumber { get; set; }
    public OrderStatus Status { get; set; }
    public decimal TotalAmount { get; set; }
    public DateTimeOffset CreatedAtUtc { get; set; }
}

public sealed class TopSellingItemDto
{
    public string Name { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal Revenue { get; set; }
}
