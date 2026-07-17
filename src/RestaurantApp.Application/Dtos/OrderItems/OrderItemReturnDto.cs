namespace RestaurantApp.Application.Dtos.OrderItems;
public class OrderItemReturnDto
{
    public int Id { get; set; }
    public string MenuItemName { get; set; } = null!;
    public int Count { get; set; }
    public decimal Price { get; set; }
}
