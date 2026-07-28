using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using RestaurantApp.Application.Security;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Dtos.Orders;
using RestaurantApp.Application.Exceptions;
using RestaurantApp.Application.Common;
using RestaurantApp.Application.Dtos.MenuItems;
using RestaurantApp.Application.Dtos.OrderItems;

namespace RestaurantApp.Web.Controllers;

[Authorize(Roles = RestaurantRoles.OrderStaff)]
public class OrderController(
    IOrderService orderService,
    IMenuItemService menuService,
    IDiningTableService tableService) : Controller
{
    public IActionResult Index()
    {
        return RedirectToAction(nameof(List));
    }

    [HttpGet]
    public async Task<IActionResult> Create()
    {
        var dto = new OrderCreateDto();
        await LoadOrderOptionsAsync(dto);
        return View(dto);
    }

    [HttpPost]
    public async Task<IActionResult> Create(OrderCreateDto dto)
    {
        if (!ModelState.IsValid)
        {
            await LoadOrderOptionsAsync(dto);
            return View(dto);
        }

        dto.OrderItems = dto.OrderItems.Where(x => x.Quantity > 0 && x.MenuItemId > 0).ToList();

        try
        {
            await orderService.AddAsync(dto);
            TempData["Success"] = "Order added successfully.";
            return RedirectToAction(nameof(Index));
        }
        catch (CountZeroException ex)
        {
            await LoadOrderOptionsAsync(dto);
            ModelState.AddModelError("", ex.Message);
            return View(dto);
        }
        catch (EntityNotFoundException ex)
        {
            await LoadOrderOptionsAsync(dto);
            ModelState.AddModelError("", ex.Message);
            return View(dto);
        }
        catch (InvalidOperationException ex)
        {
            await LoadOrderOptionsAsync(dto);
            ModelState.AddModelError("", ex.Message);
            return View(dto);
        }
    }

    [HttpGet]
    public async Task<IActionResult> List(OrderQueryDto query)
    {
        ViewBag.Query = query;
        ViewBag.DiningTables = await tableService.GetAllAsync();
        return View(await orderService.SearchAsync(query));
    }

    [HttpGet]
    public async Task<IActionResult> Details(int id)
    {
        try
        {
            var order = await orderService.GetByNoAsync(id);
            return View(order);
        }
        catch (EntityNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPost]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            await orderService.CancelAsync(id, "Cancelled by staff from the order list.");
            TempData["Success"] = "Order cancelled without deleting its history.";
        }
        catch (Exception ex) when (ex is EntityNotFoundException or InvalidOperationException or ArgumentException)
        {
            TempData["Error"] = ex.Message;
        }
        
        return RedirectToAction(nameof(List));
    }

    private async Task LoadOrderOptionsAsync(OrderCreateDto dto)
    {
        var menuItems = await menuService.GetAvailableAsync();
        var submittedItems = dto.OrderItems
            .Where(item => item.MenuItemId > 0)
            .GroupBy(item => item.MenuItemId)
            .ToDictionary(group => group.Key, group => group.First());
        dto.OrderItems = menuItems.Select(item => submittedItems.GetValueOrDefault(item.Id) ?? new OrderItemCreateDto
        {
            MenuItemId = item.Id
        }).ToList();
        ViewBag.MenuItems = menuItems;
        ViewBag.DiningTables = await tableService.GetAvailableAsync();
    }
}
