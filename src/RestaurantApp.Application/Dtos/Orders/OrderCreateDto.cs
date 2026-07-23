namespace RestaurantApp.Application.Dtos.Orders;
public class OrderCreateDto
{
    [Range(1, int.MaxValue, ErrorMessage = "Select a dining table.")]
    public int DiningTableId { get; set; }

    [StringLength(500)]
    public string? Notes { get; set; }

    public List<OrderItemCreateDto> OrderItems { get; set; } = new();
}
