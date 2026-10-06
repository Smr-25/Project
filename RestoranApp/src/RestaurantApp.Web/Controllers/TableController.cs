using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestaurantApp.Application.Dtos.DiningTables;
using RestaurantApp.Application.Exceptions;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Security;

namespace RestaurantApp.Web.Controllers;

[Authorize(Roles = RestaurantRoles.Management)]
public sealed class TableController(IDiningTableService tableService) : Controller
{
    [HttpGet]
    public async Task<IActionResult> Index() => View(await tableService.GetAllAsync());

    [HttpGet]
    public IActionResult Create() => View(new DiningTableUpsertDto());

    [HttpPost]
    public async Task<IActionResult> Create(DiningTableUpsertDto dto)
    {
        if (!ModelState.IsValid)
        {
            return View(dto);
        }

        try
        {
            await tableService.AddAsync(dto);
            TempData["Success"] = "Dining table added.";
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
        var table = await tableService.GetByIdAsync(id);
        return View(new DiningTableUpsertDto
        {
            Number = table.Number,
            Capacity = table.Capacity,
            IsActive = table.IsActive
        });
    }

    [HttpPost]
    public async Task<IActionResult> Edit(int id, DiningTableUpsertDto dto)
    {
        if (!ModelState.IsValid)
        {
            return View(dto);
        }

        try
        {
            await tableService.EditAsync(id, dto);
            TempData["Success"] = "Dining table updated.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception exception) when (exception is EntityAlreadyExistException or EntityNotFoundException or InvalidOperationException)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return View(dto);
        }
    }
}
