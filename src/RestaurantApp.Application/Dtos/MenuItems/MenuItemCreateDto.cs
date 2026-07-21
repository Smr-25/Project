namespace RestaurantApp.Application.Dtos.MenuItems;
public class MenuItemCreateDto
{
    [Required, StringLength(150, MinimumLength = 2)]
    public string Name { get; set; } = null!;

    [Required, StringLength(500, MinimumLength = 10)]
    public string Description { get; set; } = string.Empty;

    [Range(typeof(decimal), "0.01", "100000")]
    public decimal Price { get; set; }

    [Url, StringLength(500)]
    public string? ImageUrl { get; set; }

    [Range(1, int.MaxValue)]
    public int CategoryId { get; set; }

    public bool IsAvailable { get; set; } = true;
}
