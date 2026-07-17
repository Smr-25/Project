namespace RestaurantApp.Application.Dtos.Orders;
public class OrderCreateDto
{
    public List<OrderItemCreateDto> OrderItems { get; set; } = new();
}
