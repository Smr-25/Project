using System.Linq;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using HRManagementApp.Core.Interfaces;
using HRManagementApp.Business.DTOs;
using HRManagementApp.Models;
using HRManagementApp.Core.Entities;
using System.Collections.Generic;

namespace HRManagementApp.Controllers;

public class EmployeeController : Controller
{
    private readonly IHumanResourceManager _manager;

    public EmployeeController(IHumanResourceManager manager)
    {
        _manager = manager;
    }

    public IActionResult Index(string? query)
    {
        List<Employee> employees;

        if (string.IsNullOrWhiteSpace(query))
        {
            employees = _manager.GetDepartments().SelectMany(d => d.Employees).ToList();
        }
        else
        {
            employees = _manager.Search(query);
            ViewBag.SearchQuery = query;
        }

        return View(employees);
    }

    [HttpGet]
    public IActionResult Create()
    {
        var departments = _manager.GetDepartments();
        ViewBag.Departments = new SelectList(departments, "Name", "Name");
        return View(new EmployeeDto());
    }

    [HttpPost]
    public IActionResult Create(EmployeeDto dto)
    {
        if (!ModelState.IsValid)
        {
            var departments = _manager.GetDepartments();
            ViewBag.Departments = new SelectList(departments, "Name", "Name");
            return View(dto);
        }

        try
        {
            _manager.AddEmployee(dto.FullName, dto.Position, dto.Salary, dto.DepartmentName);
            TempData["SuccessMessage"] = "Employee created successfully!";
            return RedirectToAction(nameof(Index));
        }
        catch (System.Exception ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            var departments = _manager.GetDepartments();
            ViewBag.Departments = new SelectList(departments, "Name", "Name");
            return View(dto);
        }
    }

    [HttpGet]
    public IActionResult Edit(string no)
    {
        if (string.IsNullOrEmpty(no)) return BadRequest();

        var employee = _manager.GetDepartments()
            .SelectMany(d => d.Employees)
            .FirstOrDefault(e => e.No.Equals(no, System.StringComparison.OrdinalIgnoreCase));

        if (employee == null)
        {
            return NotFound();
        }

        var model = new EditEmployeeViewModel
        {
            No = employee.No,
            Position = employee.Position,
            Salary = employee.Salary
        };

        return View(model);
    }

    [HttpPost]
    public IActionResult Edit(EditEmployeeViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            _manager.EditEmployee(model.No, model.Position, model.Salary);
            TempData["SuccessMessage"] = $"Employee data updated successfully for ID: {model.No}";
            return RedirectToAction(nameof(Index));
        }
        catch (System.Exception ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(model);
        }
    }

    [HttpPost]
    public IActionResult Delete(string no, string departmentName)
    {
        try
        {
            _manager.RemoveEmployee(no, departmentName);
            TempData["SuccessMessage"] = "Employee deleted successfully!";
        }
        catch (System.Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }
}
