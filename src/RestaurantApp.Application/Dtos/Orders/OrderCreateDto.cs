namespace RestaurantApp.Application.Dtos.Orders;
public class OrderCreateDto
{
    [StringLength(500)]
    public string? Notes { get; set; }

    public List<OrderItemCreateDto> OrderItems { get; set; } = new();
}
