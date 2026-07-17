using RestaurantApp.Application.Dtos.Categories;
using RestaurantApp.Application.Dtos.MenuItems;
using RestaurantApp.Application.Dtos.OrderItems;
using RestaurantApp.Application.Dtos.Orders;
using RestaurantApp.Domain.Models;

namespace RestaurantApp.Application.Mappings;

internal static class DtoMappingExtensions
{
    internal static CategoryReturnDto ToDto(this Category category) => new()
    {
        Id = category.Id,
        Name = category.Name
    };

    internal static MenuItemReturnDto ToDto(this MenuItem menuItem) => new()
    {
        Id = menuItem.Id,
        Name = menuItem.Name,
        Price = menuItem.Price,
        CategoryName = menuItem.Category.Name
    };

    internal static OrderItemReturnDto ToDto(this OrderItem orderItem) => new()
    {
        Id = orderItem.Id,
        MenuItemName = orderItem.MenuItem.Name,
        Count = orderItem.Count,
        Price = orderItem.Price
    };

    internal static OrderReturnDto ToDto(this Order order) => new()
    {
        Id = order.Id,
        TotalAmount = order.TotalAmount,
        Date = order.Date,
        TotalItemCount = order.OrderItems.Sum(item => item.Count),
        OrderItems = order.OrderItems.Select(item => item.ToDto()).ToList()
    };
}
