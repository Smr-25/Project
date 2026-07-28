using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using RestaurantApp.Application.Security;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Dtos.MenuItems;
using RestaurantApp.Application.Exceptions;
using RestaurantApp.Application.Common;

namespace RestaurantApp.Web.Controllers;

[Authorize(Roles = RestaurantRoles.Management)]
public class MenuController(IMenuItemService menuService, ICategoryService categoryService) : Controller
{
    public IActionResult Index()
    {
        return RedirectToAction(nameof(List));
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
            return RedirectToAction(nameof(List));
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
    public async Task<IActionResult> List(MenuItemQueryDto query)
    {
        ViewBag.Categories = await categoryService.GetAllAsync();
        ViewBag.Query = query;
        return View(await menuService.SearchAsync(query));
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id)
    {
        var item = await menuService.GetByIdAsync(id);
        ViewBag.Categories = await categoryService.GetAllAsync();
        var dto = new MenuItemUpdateDto
        {
            Name = item.Name,
            Description = item.Description,
            Price = item.Price,
            ImageUrl = item.ImageUrl,
            CategoryId = item.CategoryId,
            IsAvailable = item.IsAvailable
        };
        return View(dto);
    }

    [HttpPost]
    public async Task<IActionResult> Edit(int id, MenuItemUpdateDto dto)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.Categories = await categoryService.GetAllAsync();
            return View(dto);
        }

        try
        {
            await menuService.EditAsync(id, dto);
            TempData["Success"] = "Menu item updated successfully.";
            return RedirectToAction(nameof(List));
        }
        catch (Exception ex) when (ex is EntityAlreadyExistException or EntityNotFoundException or InvalidOperationException)
        {
            ViewBag.Categories = await categoryService.GetAllAsync();
            ModelState.AddModelError("", ex.Message);
            return View(dto);
        }
    }

    [HttpPost]
    public async Task<IActionResult> SetAvailability(int id, bool isAvailable)
    {
        try
        {
            await menuService.SetAvailabilityAsync(id, isAvailable);
            TempData["Success"] = isAvailable
                ? "Menu item is available again."
                : "Menu item was archived without changing order history.";
        }
        catch (Exception ex) when (ex is EntityNotFoundException or InvalidOperationException)
        {
            TempData["Error"] = ex.Message;
        }
        
        return RedirectToAction(nameof(List));
    }
}
