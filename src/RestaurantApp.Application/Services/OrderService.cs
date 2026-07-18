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

public class OrderService(IRepository<Order> repository, IRepository<MenuItem> menuRepository) : IOrderService
{
    public async Task AddAsync(OrderCreateDto dto)
    {
        if (dto.OrderItems == null || !dto.OrderItems.Any()) throw new CountZeroException("No items.");
            
        var order = Order.Create($"ORD-{DateTimeOffset.UtcNow:yyyyMMddHHmmssfff}");
        
        foreach (var itemDto in dto.OrderItems)
        {
            if (itemDto.Count <= 0) throw new CountZeroException("Count > 0 required.");
                
            var menuItem = await menuRepository.GetByIdAsync(itemDto.MenuItemId, new string[0]);
            if (menuItem == null) throw new EntityNotFoundException("Menu item missing.");
                
            order.AddItem(menuItem, itemDto.Count);
        }
        
        await repository.AddAsync(order);
        await repository.SaveChangesAsync();
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
}
