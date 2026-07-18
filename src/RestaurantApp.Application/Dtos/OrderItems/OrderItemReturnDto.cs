namespace RestaurantApp.Application.Dtos.OrderItems;
public class OrderItemReturnDto
{
    public int Id { get; set; }
    public string MenuItemName { get; set; } = null!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public string? SpecialInstructions { get; set; }
}
