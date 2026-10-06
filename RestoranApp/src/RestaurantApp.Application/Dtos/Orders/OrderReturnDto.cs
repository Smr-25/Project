namespace RestaurantApp.Application.Dtos.Orders;
public class OrderReturnDto
{
    public int Id { get; set; }
    public string Number { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public DateTimeOffset CreatedAtUtc { get; set; }
    public OrderStatus Status { get; set; }
    public string? TableNumber { get; set; }
    public string? Notes { get; set; }
    public string? CancellationReason { get; set; }
    public int TotalItemCount { get; set; }
    public List<OrderItemReturnDto> OrderItems { get; set; } = new();
}
