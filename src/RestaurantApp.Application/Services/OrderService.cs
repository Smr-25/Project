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
using RestaurantApp.Application.Common;

public class OrderService(
    IRepository<Order> repository,
    IRepository<MenuItem> menuRepository,
    IRepository<DiningTable> tableRepository,
    IUnitOfWork unitOfWork) : IOrderService
{
    public async Task AddAsync(OrderCreateDto dto)
    {
        if (dto.OrderItems == null || !dto.OrderItems.Any()) throw new CountZeroException("No items.");
            
        var selectedItems = dto.OrderItems.Where(item => item.MenuItemId > 0 && item.Quantity > 0).ToList();
        if (selectedItems.Count == 0)
            throw new CountZeroException("Select at least one menu item.");

        var table = await tableRepository.GetByIdAsync(dto.DiningTableId, Array.Empty<string>())
            ?? throw new EntityNotFoundException("Dining table not found.");
        if (!table.IsActive)
            throw new InvalidOperationException("The selected dining table is not active.");
        if (await repository.IsExistAsync(order =>
                order.DiningTableId == table.Id &&
                order.Status != OrderStatus.Served &&
                order.Status != OrderStatus.Cancelled))
            throw new InvalidOperationException("The selected dining table already has an active order.");

        var menuItemIds = selectedItems.Select(item => item.MenuItemId).Distinct().ToArray();
        var menuItems = await menuRepository
            .GetAllAsync(item => menuItemIds.Contains(item.Id), Array.Empty<string>())
            .ToListAsync();
        if (menuItems.Count != menuItemIds.Length)
            throw new EntityNotFoundException("One or more menu items no longer exist.");

        var order = Order.Create(CreateOrderNumber(), table.Id, dto.Notes);

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

        entity.Cancel("Cancelled by restaurant staff.");
        await repository.UpdateAsync(entity);
        await repository.SaveChangesAsync();
    }

    public async Task CancelAsync(int id, string reason)
    {
        var order = await repository.GetByIdAsync(id, Array.Empty<string>())
            ?? throw new EntityNotFoundException("Order not found.");
        order.Cancel(reason);
        await repository.UpdateAsync(order);
        await repository.SaveChangesAsync();
    }

    public async Task AdvanceStatusAsync(int id)
    {
        var order = await repository.GetByIdAsync(id, Array.Empty<string>())
            ?? throw new EntityNotFoundException("Order not found.");
        var nextStatus = order.Status switch
        {
            OrderStatus.Pending => OrderStatus.Preparing,
            OrderStatus.Preparing => OrderStatus.Ready,
            OrderStatus.Ready => OrderStatus.Served,
            _ => throw new InvalidOperationException("This order cannot be advanced.")
        };

        order.MoveTo(nextStatus);
        await repository.UpdateAsync(order);
        await repository.SaveChangesAsync();
    }

    public async Task<List<OrderReturnDto>> GetKitchenBoardAsync()
    {
        var orders = await repository.GetAllAsync(
                order => order.Status == OrderStatus.Pending ||
                         order.Status == OrderStatus.Preparing ||
                         order.Status == OrderStatus.Ready,
                "OrderItems.MenuItem",
                "DiningTable")
            .OrderBy(order => order.CreatedAtUtc)
            .ToListAsync();
        return orders.Select(order => order.ToDto()).ToList();
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

    public async Task<PagedResult<OrderReturnDto>> SearchAsync(OrderQueryDto query)
    {
        var source = repository.GetAllAsync(null, "OrderItems.MenuItem", "DiningTable");
        if (query.StartDate.HasValue)
        {
            var start = new DateTimeOffset(query.StartDate.Value.Date);
            source = source.Where(order => order.CreatedAtUtc >= start);
        }
        if (query.EndDate.HasValue)
        {
            var endExclusive = new DateTimeOffset(query.EndDate.Value.Date).AddDays(1);
            source = source.Where(order => order.CreatedAtUtc < endExclusive);
        }
        if (query.MinAmount.HasValue)
            source = source.Where(order => order.TotalAmount >= query.MinAmount.Value);
        if (query.MaxAmount.HasValue)
            source = source.Where(order => order.TotalAmount <= query.MaxAmount.Value);
        if (query.Status.HasValue)
            source = source.Where(order => order.Status == query.Status.Value);
        if (query.DiningTableId.HasValue)
            source = source.Where(order => order.DiningTableId == query.DiningTableId.Value);

        var totalCount = await source.CountAsync();
        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 5, 50);
        var items = await source
            .OrderByDescending(order => order.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<OrderReturnDto>
        {
            Items = items.Select(order => order.ToDto()).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    private static string CreateOrderNumber()
    {
        var suffix = RandomNumberGenerator.GetInt32(100000, 1000000);
        return $"ORD-{DateTimeOffset.UtcNow:yyyyMMdd}-{suffix}";
    }
}
