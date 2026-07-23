using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using RestaurantApp.Application.Security;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Dtos.Orders;
using RestaurantApp.Application.Exceptions;

namespace RestaurantApp.Web.Controllers;

[Authorize(Roles = RestaurantRoles.OrderStaff)]
public class OrderController(
    IOrderService orderService,
    IMenuItemService menuService,
    IDiningTableService tableService) : Controller
{
    public IActionResult Index()
    {
        return View();
    }

    [HttpGet]
    public async Task<IActionResult> Create()
    {
        await LoadOrderOptionsAsync();
        return View(new OrderCreateDto());
    }

    [HttpPost]
    public async Task<IActionResult> Create(OrderCreateDto dto)
    {
        if (!ModelState.IsValid)
        {
            await LoadOrderOptionsAsync();
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
            await LoadOrderOptionsAsync();
            ModelState.AddModelError("", ex.Message);
            return View(dto);
        }
        catch (EntityNotFoundException ex)
        {
            await LoadOrderOptionsAsync();
            ModelState.AddModelError("", ex.Message);
            return View(dto);
        }
        catch (Exception ex)
        {
            await LoadOrderOptionsAsync();
            ModelState.AddModelError("", "An unexpected error occurred: " + ex.Message);
            return View(dto);
        }
    }

    [HttpGet]
    public async Task<IActionResult> List(DateTime? startDate, DateTime? endDate, decimal? minAmount, decimal? maxAmount, DateTime? exactDate)
    {
        IEnumerable<OrderReturnDto> items;

        if (startDate.HasValue && endDate.HasValue)
            items = await orderService.GetByDateIntervalAsync(startDate.Value, endDate.Value);
        else if (minAmount.HasValue && maxAmount.HasValue)
            items = await orderService.GetByPriceIntervalAsync(minAmount.Value, maxAmount.Value);
        else if (exactDate.HasValue)
            items = await orderService.GetByDateAsync(exactDate.Value);
        else
            items = await orderService.GetAllAsync();

        return View(items);
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
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }
        
        return RedirectToAction(nameof(List));
    }

    private async Task LoadOrderOptionsAsync()
    {
        ViewBag.MenuItems = await menuService.GetAvailableAsync();
        ViewBag.DiningTables = await tableService.GetAvailableAsync();
    }
}
