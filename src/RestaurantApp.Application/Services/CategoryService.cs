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
        var data = await repository.GetAllAsync(null, Array.Empty<string>())
            .OrderBy(category => category.DisplayOrder)
            .ThenBy(category => category.Name)
            .ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }

    public async Task<CategoryReturnDto> GetByIdAsync(int id)
    {
        var category = await repository.GetByIdAsync(id, Array.Empty<string>());
        return category?.ToDto() ?? throw new EntityNotFoundException("Category not found.");
    }

    public async Task AddAsync(CategoryUpsertDto dto)
    {
        var name = dto.Name.Trim();
        if (await repository.IsExistAsync(category => category.Name.ToLower() == name.ToLower()))
        {
            throw new EntityAlreadyExistException("A category with this name already exists.");
        }

        await repository.AddAsync(new Category
        {
            Name = name,
            Description = dto.Description.Trim(),
            DisplayOrder = dto.DisplayOrder,
            IsActive = dto.IsActive
        });
        await repository.SaveChangesAsync();
    }

    public async Task EditAsync(int id, CategoryUpsertDto dto)
    {
        var category = await repository.GetByIdAsync(id, Array.Empty<string>())
            ?? throw new EntityNotFoundException("Category not found.");
        var name = dto.Name.Trim();
        if (await repository.IsExistAsync(item => item.Id != id && item.Name.ToLower() == name.ToLower()))
        {
            throw new EntityAlreadyExistException("A category with this name already exists.");
        }

        category.Name = name;
        category.Description = dto.Description.Trim();
        category.DisplayOrder = dto.DisplayOrder;
        category.IsActive = dto.IsActive;
        repository.Update(category);
        await repository.SaveChangesAsync();
    }

    public async Task RemoveAsync(int id)
    {
        var category = await repository.GetByIdAsync(id, "MenuItems")
            ?? throw new EntityNotFoundException("Category not found.");
        if (category.MenuItems.Count > 0)
        {
            throw new InvalidOperationException("A category with menu items cannot be deleted. Archive it instead.");
        }

        repository.Remove(category);
        await repository.SaveChangesAsync();
    }
}
