namespace RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Dtos.MenuItems;
using System.Collections.Generic;
using System.Threading.Tasks;

public interface IMenuItemService
{
    Task AddAsync(MenuItemCreateDto dto);
    Task EditAsync(int id, MenuItemUpdateDto dto);
    Task RemoveAsync(int id);
    Task<MenuItemReturnDto> GetByIdAsync(int id);
    Task SetAvailabilityAsync(int id, bool isAvailable);
    Task<List<MenuItemReturnDto>> GetAllAsync();
    Task<List<MenuItemReturnDto>> GetByCategoryAsync(int categoryId);
    Task<List<MenuItemReturnDto>> GetByPriceIntervalAsync(decimal minPrice, decimal maxPrice);
    Task<List<MenuItemReturnDto>> SearchByNameAsync(string searchText);
}
