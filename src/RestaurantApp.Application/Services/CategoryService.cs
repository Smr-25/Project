namespace RestaurantApp.Application.Services;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Dtos.Categories;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Models;
using RestaurantApp.Application.Abstractions;
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
