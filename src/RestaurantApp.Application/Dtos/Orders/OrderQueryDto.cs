namespace RestaurantApp.Application.Dtos.Orders;

public sealed class OrderQueryDto
{
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public decimal? MinAmount { get; set; }
    public decimal? MaxAmount { get; set; }
    public OrderStatus? Status { get; set; }
    public int? DiningTableId { get; set; }
    [Range(1, int.MaxValue)] public int Page { get; set; } = 1;
    [Range(5, 50)] public int PageSize { get; set; } = 10;
}
