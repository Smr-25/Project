using Microsoft.AspNetCore.Mvc;
using HRManagementApp.Models;
using System.Diagnostics;
using HRManagementApp.Core.Interfaces;
using System.Linq;

namespace HRManagementApp.Controllers;

public class HomeController(IHumanResourceManager manager) : Controller
{
    public IActionResult Index()
    {
        var departments = manager.GetDepartments();
        ViewData["TotalDepartments"] = departments.Count;
        ViewData["TotalEmployees"] = departments.Sum(d => d.Employees?.Count ?? 0);
        ViewData["TotalSalary"] = departments.SelectMany(d => d.Employees ?? new System.Collections.Generic.List<HRManagementApp.Core.Entities.Employee>()).Sum(e => e.Salary);

        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
