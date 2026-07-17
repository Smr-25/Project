using Microsoft.AspNetCore.Mvc;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Dtos.MenuItems;
using RestaurantApp.Application.Exceptions;

namespace RestaurantApp.Web.Controllers;

public class MenuController(IMenuItemService menuService, ICategoryService categoryService) : Controller
{
    public IActionResult Index()
    {
        return View();
    }

    [HttpGet]
    public async Task<IActionResult> Create()
    {
        ViewBag.Categories = await categoryService.GetAllAsync();
        return View(new MenuItemCreateDto());
    }

    [HttpPost]
    public async Task<IActionResult> Create(MenuItemCreateDto dto)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Categories = await categoryService.GetAllAsync();
            return View(dto);
        }

        try
        {
            await menuService.AddAsync(dto);
            TempData["Success"] = "Menu item added successfully.";
            return RedirectToAction(nameof(Index));
        }
        catch (EntityAlreadyExistException ex)
        {
            ViewBag.Categories = await categoryService.GetAllAsync();
            ModelState.AddModelError("", ex.Message);
            return View(dto);
        }
        catch (EntityNotFoundException ex)
        {
            ViewBag.Categories = await categoryService.GetAllAsync();
            ModelState.AddModelError("", ex.Message);
            return View(dto);
        }
    }

    [HttpGet]
    public async Task<IActionResult> List(int? categoryId, decimal? minPrice, decimal? maxPrice, string? searchText)
    {
        ViewBag.Categories = await categoryService.GetAllAsync();
        IEnumerable<MenuItemReturnDto> items;

        if (categoryId.HasValue)
            items = await menuService.GetByCategoryAsync(categoryId.Value);
        else if (minPrice.HasValue && maxPrice.HasValue)
            items = await menuService.GetByPriceIntervalAsync(minPrice.Value, maxPrice.Value);
        else if (!string.IsNullOrWhiteSpace(searchText))
            items = await menuService.SearchByNameAsync(searchText);
        else
            items = await menuService.GetAllAsync();

        return View(items);
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id)
    {
        var items = await menuService.GetAllAsync();
        var item = items.FirstOrDefault(x => x.Id == id);
        if (item == null) return NotFound();
        
        var dto = new MenuItemUpdateDto { Name = item.Name, Price = item.Price };
        return View(dto);
    }

    [HttpPost]
    public async Task<IActionResult> Edit(int id, MenuItemUpdateDto dto)
    {
        if (!ModelState.IsValid) return View(dto);

        try
        {
            await menuService.EditAsync(id, dto);
            TempData["Success"] = "Menu item updated successfully.";
            return RedirectToAction(nameof(List));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", ex.Message);
            return View(dto);
        }
    }

    [HttpPost]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            await menuService.RemoveAsync(id);
            TempData["Success"] = "Menu item deleted successfully.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }
        
        return RedirectToAction(nameof(List));
    }
}
