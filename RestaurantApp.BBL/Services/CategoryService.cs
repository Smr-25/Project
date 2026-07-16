namespace RestaurantApp.BBL.Services;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.BBL.Dtos.Categories;
using RestaurantApp.BBL.Interfaces;
using RestaurantApp.Core.Models;
using RestaurantApp.DDL.Repositories.Interfaces;
using System.Collections.Generic;
using System.Threading.Tasks;

public class CategoryService(IRepository<Category> repository) : ICategoryService
{
    public async Task<List<CategoryReturnDto>> GetAllAsync()
    {
        var data = await repository.GetAllAsync(null, new string[0]).ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }
}
