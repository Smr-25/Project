namespace RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Dtos.Categories;
using System.Collections.Generic;
using System.Threading.Tasks;

public interface ICategoryService
{
    Task<List<CategoryReturnDto>> GetAllAsync();
    Task<CategoryReturnDto> GetByIdAsync(int id);
    Task AddAsync(CategoryUpsertDto dto);
    Task EditAsync(int id, CategoryUpsertDto dto);
    Task RemoveAsync(int id);
}
