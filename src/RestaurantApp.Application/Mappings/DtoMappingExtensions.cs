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
        Name = category.Name,
        Description = category.Description,
        DisplayOrder = category.DisplayOrder,
        IsActive = category.IsActive
    };

    internal static MenuItemReturnDto ToDto(this MenuItem menuItem) => new()
    {
        Id = menuItem.Id,
        Name = menuItem.Name,
        Description = menuItem.Description,
        Price = menuItem.Price,
        ImageUrl = menuItem.ImageUrl,
        IsAvailable = menuItem.IsAvailable,
        CategoryId = menuItem.CategoryId,
        CategoryName = menuItem.Category.Name
    };

    internal static OrderItemReturnDto ToDto(this OrderItem orderItem) => new()
    {
        Id = orderItem.Id,
        MenuItemName = orderItem.MenuItem.Name,
        Quantity = orderItem.Quantity,
        UnitPrice = orderItem.UnitPrice,
        SpecialInstructions = orderItem.SpecialInstructions
    };

    internal static OrderReturnDto ToDto(this Order order) => new()
    {
        Id = order.Id,
        Number = order.Number,
        TotalAmount = order.TotalAmount,
        CreatedAtUtc = order.CreatedAtUtc,
        Status = order.Status,
        TableNumber = order.DiningTable?.Number,
        Notes = order.Notes,
        CancellationReason = order.CancellationReason,
        TotalItemCount = order.OrderItems.Sum(item => item.Quantity),
        OrderItems = order.OrderItems.Select(item => item.ToDto()).ToList()
    };
}
