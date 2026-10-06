namespace RestaurantApp.Application.Dtos.MenuItems;

public sealed class MenuItemQueryDto
{
    public string? Search { get; set; }
    public int? CategoryId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public bool? IsAvailable { get; set; }
    [Range(1, int.MaxValue)] public int Page { get; set; } = 1;
    [Range(5, 50)] public int PageSize { get; set; } = 10;
}
