using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using RestaurantApp.Application.Interfaces;
using RestaurantApp.Web.Models;

namespace RestaurantApp.Web.Controllers;

public class HomeController(IDashboardService dashboardService) : Controller
{
    [Authorize]
    public async Task<IActionResult> Index()
    {
        return View(await dashboardService.GetAsync());
    }

    [AllowAnonymous]
    public IActionResult Privacy()
    {
        return View();
    }

    [HttpGet]
    [AllowAnonymous]
    public IActionResult ErrorStatus(int code)
    {
        Response.StatusCode = code;
        ViewBag.StatusCode = code;
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    [AllowAnonymous]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
