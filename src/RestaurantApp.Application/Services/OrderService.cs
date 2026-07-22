namespace RestaurantApp.Application.Services;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Dtos.Orders;
using RestaurantApp.Application.Exceptions;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Models;
using RestaurantApp.Application.Abstractions;
using System.Collections.Generic;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Security.Cryptography;

public class OrderService(
    IRepository<Order> repository,
    IRepository<MenuItem> menuRepository,
    IUnitOfWork unitOfWork) : IOrderService
{
    public async Task AddAsync(OrderCreateDto dto)
    {
        if (dto.OrderItems == null || !dto.OrderItems.Any()) throw new CountZeroException("No items.");
            
        var selectedItems = dto.OrderItems.Where(item => item.MenuItemId > 0 && item.Quantity > 0).ToList();
        if (selectedItems.Count == 0)
            throw new CountZeroException("Select at least one menu item.");

        var menuItemIds = selectedItems.Select(item => item.MenuItemId).Distinct().ToArray();
        var menuItems = await menuRepository
            .GetAllAsync(item => menuItemIds.Contains(item.Id), Array.Empty<string>())
            .ToListAsync();
        if (menuItems.Count != menuItemIds.Length)
            throw new EntityNotFoundException("One or more menu items no longer exist.");

        var order = Order.Create(CreateOrderNumber(), notes: dto.Notes);

        foreach (var itemDto in selectedItems)
        {
            var menuItem = menuItems.Single(item => item.Id == itemDto.MenuItemId);
            order.AddItem(menuItem, itemDto.Quantity, itemDto.SpecialInstructions);
        }

        await unitOfWork.ExecuteInTransactionAsync(async _ => await repository.AddAsync(order));
    }
    
    public async Task RemoveAsync(int id)
    {
        var entity = await repository.GetByIdAsync(id, new string[0]);
        if (entity == null) throw new EntityNotFoundException("Not found.");
            
        await repository.RemoveAsync(entity);
        await repository.SaveChangesAsync();
    }
    
    public async Task<List<OrderReturnDto>> GetAllAsync()
    {
        var data = await repository.GetAllAsync(null, "OrderItems.MenuItem", "DiningTable").ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }
    
    public async Task<List<OrderReturnDto>> GetByDateIntervalAsync(DateTime startDate, DateTime endDate)
    {
        var start = new DateTimeOffset(startDate);
        var end = new DateTimeOffset(endDate);
        var data = await repository.GetAllAsync(
            x => x.CreatedAtUtc >= start && x.CreatedAtUtc <= end,
            "OrderItems.MenuItem",
            "DiningTable").ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }
    
    public async Task<List<OrderReturnDto>> GetByPriceIntervalAsync(decimal minAmount, decimal maxAmount)
    {
        var data = await repository.GetAllAsync(
            x => x.TotalAmount >= minAmount && x.TotalAmount <= maxAmount,
            "OrderItems.MenuItem",
            "DiningTable").ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }
    
    public async Task<List<OrderReturnDto>> GetByDateAsync(DateTime date)
    {
        var start = new DateTimeOffset(date.Date);
        var end = start.AddDays(1);
        var data = await repository.GetAllAsync(
            x => x.CreatedAtUtc >= start && x.CreatedAtUtc < end,
            "OrderItems.MenuItem",
            "DiningTable").ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }
    
    public async Task<OrderReturnDto> GetByNoAsync(int id)
    {
        var data = await repository.GetAsync(x => x.Id == id, "OrderItems.MenuItem", "DiningTable");
        if (data == null) throw new EntityNotFoundException("Not found.");
            
        return data.ToDto();
    }

    private static string CreateOrderNumber()
    {
        var suffix = RandomNumberGenerator.GetInt32(100000, 1000000);
        return $"ORD-{DateTimeOffset.UtcNow:yyyyMMdd}-{suffix}";
    }
}
