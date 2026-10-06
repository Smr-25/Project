using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Abstractions;
using RestaurantApp.Application.Dtos.Dashboard;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Models;

namespace RestaurantApp.Application.Services;

public sealed class DashboardService(
    IRepository<Order> orderRepository,
    IRepository<OrderItem> orderItemRepository,
    IRepository<MenuItem> menuItemRepository) : IDashboardService
{
    public async Task<DashboardDto> GetAsync()
    {
        var today = new DateTimeOffset(DateTime.UtcNow.Date, TimeSpan.Zero);
        var tomorrow = today.AddDays(1);
        var orders = orderRepository.GetAllAsync(null, "DiningTable");
        var todayOrders = orders.Where(order =>
            order.CreatedAtUtc >= today &&
            order.CreatedAtUtc < tomorrow &&
            order.Status != OrderStatus.Cancelled);

        var todayOrderCount = await todayOrders.CountAsync();
        var todayRevenue = await todayOrders.SumAsync(order => (decimal?)order.TotalAmount) ?? 0;
        var recentOrders = await orders
            .OrderByDescending(order => order.CreatedAtUtc)
            .Take(6)
            .Select(order => new DashboardOrderDto
            {
                Id = order.Id,
                Number = order.Number,
                TableNumber = order.DiningTable == null ? null : order.DiningTable.Number,
                Status = order.Status,
                TotalAmount = order.TotalAmount,
                CreatedAtUtc = order.CreatedAtUtc
            })
            .ToListAsync();

        var topSellingItems = await orderItemRepository
            .GetAllAsync(item => item.Order.Status != OrderStatus.Cancelled, "MenuItem", "Order")
            .GroupBy(item => item.MenuItem.Name)
            .Select(group => new TopSellingItemDto
            {
                Name = group.Key,
                Quantity = group.Sum(item => item.Quantity),
                Revenue = group.Sum(item => item.Quantity * item.UnitPrice)
            })
            .OrderByDescending(item => item.Quantity)
            .Take(5)
            .ToListAsync();

        return new DashboardDto
        {
            TodayRevenue = todayRevenue,
            TodayOrderCount = todayOrderCount,
            ActiveOrderCount = await orders.CountAsync(order =>
                order.Status != OrderStatus.Served && order.Status != OrderStatus.Cancelled),
            AverageTicket = todayOrderCount == 0 ? 0 : todayRevenue / todayOrderCount,
            AvailableMenuItemCount = await menuItemRepository.GetAllAsync(
                item => item.IsAvailable && item.Category.IsActive,
                Array.Empty<string>()).CountAsync(),
            OccupiedTableCount = await orders
                .Where(order => order.Status != OrderStatus.Served && order.Status != OrderStatus.Cancelled)
                .Select(order => order.DiningTableId)
                .Distinct()
                .CountAsync(),
            RecentOrders = recentOrders,
            TopSellingItems = topSellingItems
        };
    }
}
