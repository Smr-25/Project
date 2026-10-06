using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Application.Exceptions;
using RestaurantApp.Application.Security;

namespace RestaurantApp.Web.Controllers;

[Authorize(Roles = RestaurantRoles.Admin + "," + RestaurantRoles.Manager + "," + RestaurantRoles.Kitchen)]
public sealed class KitchenController(IOrderService orderService) : Controller
{
    [HttpGet]
    public async Task<IActionResult> Index() => View(await orderService.GetKitchenBoardAsync());

    [HttpPost]
    public async Task<IActionResult> Advance(int id)
    {
        try
        {
            await orderService.AdvanceStatusAsync(id);
        }
        catch (Exception exception) when (exception is EntityNotFoundException or InvalidOperationException)
        {
            TempData["Error"] = exception.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Cancel(int id, string reason)
    {
        try
        {
            await orderService.CancelAsync(id, reason);
        }
        catch (Exception exception) when (exception is EntityNotFoundException or InvalidOperationException or ArgumentException)
        {
            TempData["Error"] = exception.Message;
        }

        return RedirectToAction(nameof(Index));
    }
}
