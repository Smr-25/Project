using Microsoft.AspNetCore.Mvc;
using HRManagementApp.Models;
using System.Diagnostics;
using HRManagementApp.Core.Interfaces;

namespace HRManagementApp.Controllers;

public class HomeController(IHumanResourceManager manager) : Controller
{
    public IActionResult Index()
    {
        var departments = manager.GetDepartments();
        return View(new DashboardViewModel
        {
            TotalDepartments = departments.Count,
            TotalEmployees = departments.Sum(department => department.Employees.Count),
            MonthlySalary = departments.SelectMany(department => department.Employees)
                .Sum(employee => employee.Salary),
            Departments = departments.Select(department => new DepartmentOverview(
                department.Name,
                department.Employees.Count,
                department.WorkerLimit,
                department.Employees.Sum(employee => employee.Salary),
                department.SalaryLimit)).ToList()
        });
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
