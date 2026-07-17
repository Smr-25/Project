namespace RestaurantApp.Application.Dtos.MenuItems;
public class MenuItemReturnDto
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public decimal Price { get; set; }
    public string CategoryName { get; set; } = null!;
}
