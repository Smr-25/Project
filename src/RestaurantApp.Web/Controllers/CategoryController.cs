using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestaurantApp.Application.Dtos.Categories;
using RestaurantApp.Application.Exceptions;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Security;

namespace RestaurantApp.Web.Controllers;

[Authorize(Roles = RestaurantRoles.Management)]
public sealed class CategoryController(ICategoryService categoryService) : Controller
{
    [HttpGet]
    public async Task<IActionResult> Index() => View(await categoryService.GetAllAsync());

    [HttpGet]
    public IActionResult Create() => View(new CategoryUpsertDto());

    [HttpPost]
    public async Task<IActionResult> Create(CategoryUpsertDto dto)
    {
        if (!ModelState.IsValid)
        {
            return View(dto);
        }

        try
        {
            await categoryService.AddAsync(dto);
            TempData["Success"] = "Category created.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception exception) when (exception is EntityAlreadyExistException or InvalidOperationException)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return View(dto);
        }
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id)
    {
        var category = await categoryService.GetByIdAsync(id);
        return View(new CategoryUpsertDto
        {
            Name = category.Name,
            Description = category.Description,
            DisplayOrder = category.DisplayOrder,
            IsActive = category.IsActive
        });
    }

    [HttpPost]
    public async Task<IActionResult> Edit(int id, CategoryUpsertDto dto)
    {
        if (!ModelState.IsValid)
        {
            return View(dto);
        }

        try
        {
            await categoryService.EditAsync(id, dto);
            TempData["Success"] = "Category updated.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception exception) when (exception is EntityAlreadyExistException or EntityNotFoundException or InvalidOperationException)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return View(dto);
        }
    }

    [HttpPost]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            await categoryService.RemoveAsync(id);
            TempData["Success"] = "Empty category deleted.";
        }
        catch (Exception exception) when (exception is EntityNotFoundException or InvalidOperationException)
        {
            TempData["Error"] = exception.Message;
        }

        return RedirectToAction(nameof(Index));
    }
}
