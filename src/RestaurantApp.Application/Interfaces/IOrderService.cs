namespace RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Dtos.Orders;
using System.Collections.Generic;
using System;
using System.Threading.Tasks;

public interface IOrderService
{
    Task AddAsync(OrderCreateDto dto);
    Task RemoveAsync(int id);
    Task<List<OrderReturnDto>> GetAllAsync();
    Task<List<OrderReturnDto>> GetByDateIntervalAsync(DateTime startDate, DateTime endDate);
    Task<List<OrderReturnDto>> GetByPriceIntervalAsync(decimal minAmount, decimal maxAmount);
    Task<List<OrderReturnDto>> GetByDateAsync(DateTime date);
    Task<OrderReturnDto> GetByNoAsync(int id);
}
