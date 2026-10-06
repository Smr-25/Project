namespace RestaurantApp.Application.Dtos.OrderItems;
public class OrderItemCreateDto
{
    public int MenuItemId { get; set; }

    public int Quantity { get; set; }

    [StringLength(300)]
    public string? SpecialInstructions { get; set; }
}
