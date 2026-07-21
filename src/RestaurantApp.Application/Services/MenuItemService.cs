namespace RestaurantApp.Application.Services;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Dtos.MenuItems;
using RestaurantApp.Application.Exceptions;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Models;
using RestaurantApp.Application.Abstractions;
using System.Collections.Generic;
using System.Threading.Tasks;

public class MenuItemService(IRepository<MenuItem> repository, IRepository<Category> categoryRepository) : IMenuItemService
{
    public async Task AddAsync(MenuItemCreateDto dto)
    {
        if (await repository.IsExistAsync(x => x.Name.ToLower() == dto.Name.ToLower().Trim()))
            throw new EntityAlreadyExistException("Item with this name already exists.");
        
        if (!await categoryRepository.IsExistAsync(x => x.Id == dto.CategoryId && x.IsActive))
            throw new EntityNotFoundException("An active category was not found.");
            
        var entity = new MenuItem
        {
            Name = dto.Name.Trim(),
            Description = dto.Description.Trim(),
            Price = dto.Price,
            ImageUrl = Normalize(dto.ImageUrl),
            CategoryId = dto.CategoryId,
            IsAvailable = dto.IsAvailable
        };
        await repository.AddAsync(entity);
        await repository.SaveChangesAsync();
    }
    
    public async Task EditAsync(int id, MenuItemUpdateDto dto)
    {
        var entity = await repository.GetByIdAsync(id, new string[0]);
        if (entity == null)
            throw new EntityNotFoundException("Not found.");
            
        if (entity.Name.ToLower() != dto.Name.ToLower().Trim() && await repository.IsExistAsync(x => x.Name.ToLower() == dto.Name.ToLower().Trim() && x.Id != id))
            throw new EntityAlreadyExistException("Already exists.");
            
        if (!await categoryRepository.IsExistAsync(x => x.Id == dto.CategoryId && x.IsActive))
            throw new EntityNotFoundException("An active category was not found.");

        entity.Name = dto.Name.Trim();
        entity.Description = dto.Description.Trim();
        entity.Price = dto.Price;
        entity.ImageUrl = Normalize(dto.ImageUrl);
        entity.CategoryId = dto.CategoryId;
        entity.IsAvailable = dto.IsAvailable;
        await repository.UpdateAsync(entity);
        await repository.SaveChangesAsync();
    }
    
    public async Task RemoveAsync(int id)
    {
        var entity = await repository.GetByIdAsync(id, new string[0]);
        if (entity == null) throw new EntityNotFoundException("Not found.");
            
        entity.IsAvailable = false;
        await repository.UpdateAsync(entity);
        await repository.SaveChangesAsync();
    }

    public async Task<MenuItemReturnDto> GetByIdAsync(int id)
    {
        var entity = await repository.GetByIdAsync(id, "Category")
            ?? throw new EntityNotFoundException("Menu item not found.");
        return entity.ToDto();
    }

    public async Task SetAvailabilityAsync(int id, bool isAvailable)
    {
        var entity = await repository.GetByIdAsync(id, Array.Empty<string>())
            ?? throw new EntityNotFoundException("Menu item not found.");
        entity.IsAvailable = isAvailable;
        await repository.UpdateAsync(entity);
        await repository.SaveChangesAsync();
    }
    
    public async Task<List<MenuItemReturnDto>> GetAllAsync()
    {
        var data = await repository.GetAllAsync(null, "Category").ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }
    
    public async Task<List<MenuItemReturnDto>> GetByCategoryAsync(int categoryId)
    {
        var data = await repository.GetAllAsync(x => x.CategoryId == categoryId, "Category").ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }
    
    public async Task<List<MenuItemReturnDto>> GetByPriceIntervalAsync(decimal minPrice, decimal maxPrice)
    {
        var data = await repository.GetAllAsync(x => x.Price >= minPrice && x.Price <= maxPrice, "Category").ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }
    
    public async Task<List<MenuItemReturnDto>> SearchByNameAsync(string searchText)
    {
        var data = await repository.GetAllAsync(x => x.Name.ToLower().Contains(searchText.ToLower().Trim()), "Category").ToListAsync();
        return data.Select(item => item.ToDto()).ToList();
    }

    private static string? Normalize(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
