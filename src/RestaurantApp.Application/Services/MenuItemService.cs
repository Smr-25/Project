namespace RestaurantApp.Application.Services;
using Microsoft.EntityFrameworkCore;
using RestaurantApp.Application.Dtos.MenuItems;
using RestaurantApp.Application.Exceptions;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Domain.Models;
using RestaurantApp.Application.Abstractions;
using RestaurantApp.Application.Common;
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

    public async Task<List<MenuItemReturnDto>> GetAvailableAsync()
    {
        var data = await repository
            .GetAllAsync(item => item.IsAvailable && item.Category.IsActive, "Category")
            .OrderBy(item => item.Category.DisplayOrder)
            .ThenBy(item => item.Name)
            .ToListAsync();
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

    public async Task<PagedResult<MenuItemReturnDto>> SearchAsync(MenuItemQueryDto query)
    {
        var source = repository.GetAllAsync(null, "Category");
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            source = source.Where(item => item.Name.ToLower().Contains(search));
        }
        if (query.CategoryId.HasValue)
            source = source.Where(item => item.CategoryId == query.CategoryId.Value);
        if (query.MinPrice.HasValue)
            source = source.Where(item => item.Price >= query.MinPrice.Value);
        if (query.MaxPrice.HasValue)
            source = source.Where(item => item.Price <= query.MaxPrice.Value);
        if (query.IsAvailable.HasValue)
            source = source.Where(item => item.IsAvailable == query.IsAvailable.Value);

        var totalCount = await source.CountAsync();
        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 5, 50);
        var items = await source
            .OrderBy(item => item.Category.DisplayOrder)
            .ThenBy(item => item.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<MenuItemReturnDto>
        {
            Items = items.Select(item => item.ToDto()).ToList(),
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount
        };
    }

    private static string? Normalize(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
