namespace RestaurantApp.Application.Dtos.Orders;
public class OrderReturnDto
{
    public int Id { get; set; }
    public decimal TotalAmount { get; set; }
    public DateTime Date { get; set; }
    public int TotalItemCount { get; set; }
    public List<OrderItemReturnDto> OrderItems { get; set; } = new();
}
