using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Abstractions;
using RestaurantApp.Application.Dtos.DiningTables;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Models;

namespace RestaurantApp.Application.Services;

public sealed class DiningTableService(
    IRepository<DiningTable> tableRepository,
    IRepository<Order> orderRepository) : IDiningTableService
{
    public async Task<List<DiningTableReturnDto>> GetAllAsync()
    {
        var tables = await tableRepository.GetAllAsync(null, Array.Empty<string>())
            .OrderBy(table => table.Number)
            .ToListAsync();
        var activeOrders = await GetActiveOrdersAsync();
        return tables.Select(table => Map(table, activeOrders)).ToList();
    }

    public async Task<List<DiningTableReturnDto>> GetAvailableAsync()
    {
        var tables = await GetAllAsync();
        return tables.Where(table => table.IsActive && !table.IsOccupied).ToList();
    }

    public async Task<DiningTableReturnDto> GetByIdAsync(int id)
    {
        var table = await tableRepository.GetByIdAsync(id, Array.Empty<string>())
            ?? throw new EntityNotFoundException("Dining table not found.");
        return Map(table, await GetActiveOrdersAsync());
    }

    public async Task AddAsync(DiningTableUpsertDto dto)
    {
        var number = dto.Number.Trim();
        if (await tableRepository.IsExistAsync(table => table.Number.ToLower() == number.ToLower()))
        {
            throw new EntityAlreadyExistException("A table with this number already exists.");
        }

        await tableRepository.AddAsync(new DiningTable
        {
            Number = number,
            Capacity = dto.Capacity,
            IsActive = dto.IsActive
        });
        await tableRepository.SaveChangesAsync();
    }

    public async Task EditAsync(int id, DiningTableUpsertDto dto)
    {
        var table = await tableRepository.GetByIdAsync(id, Array.Empty<string>())
            ?? throw new EntityNotFoundException("Dining table not found.");
        var number = dto.Number.Trim();
        if (await tableRepository.IsExistAsync(item => item.Id != id && item.Number.ToLower() == number.ToLower()))
        {
            throw new EntityAlreadyExistException("A table with this number already exists.");
        }

        table.Number = number;
        table.Capacity = dto.Capacity;
        table.IsActive = dto.IsActive;
        tableRepository.Update(table);
        await tableRepository.SaveChangesAsync();
    }

    private async Task<List<Order>> GetActiveOrdersAsync() => await orderRepository
        .GetAllAsync(
            order => order.Status != OrderStatus.Served && order.Status != OrderStatus.Cancelled,
            Array.Empty<string>())
        .ToListAsync();

    private static DiningTableReturnDto Map(DiningTable table, IReadOnlyCollection<Order> activeOrders)
    {
        var order = activeOrders.FirstOrDefault(item => item.DiningTableId == table.Id);
        return new DiningTableReturnDto
        {
            Id = table.Id,
            Number = table.Number,
            Capacity = table.Capacity,
            IsActive = table.IsActive,
            IsOccupied = order is not null,
            ActiveOrderNumber = order?.Number
        };
    }
}
