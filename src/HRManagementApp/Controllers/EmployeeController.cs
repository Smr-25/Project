using FluentValidation;
using HRManagementApp.Business.DTOs;
using HRManagementApp.Business.Services;
using HRManagementApp.Core.Interfaces;
using HRManagementApp.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace HRManagementApp.Controllers;

public class EmployeeController(
    IHumanResourceManager manager,
    IValidator<EmployeeDto> validator) : Controller
{
    public IActionResult Index(string? query)
    {
        ViewBag.SearchQuery = query;
        var employees = string.IsNullOrWhiteSpace(query)
            ? manager.GetEmployees()
            : manager.Search(query);
        return View(employees);
    }

    [HttpGet]
    public IActionResult Create()
    {
        SetDepartments();
        return View(new EmployeeDto());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Create(EmployeeDto dto)
    {
        var validation = validator.Validate(dto);
        foreach (var error in validation.Errors)
            ModelState.AddModelError(error.PropertyName, error.ErrorMessage);
        if (!ModelState.IsValid)
        {
            SetDepartments();
            return View(dto);
        }

        try
        {
            manager.AddEmployee(dto.FullName, dto.Position, dto.Salary, dto.DepartmentId);
            TempData["SuccessMessage"] = "Employee created successfully.";
            return RedirectToAction(nameof(Index));
        }
        catch (BusinessRuleException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            SetDepartments();
            return View(dto);
        }
    }

    [HttpGet]
    public IActionResult Edit(int id)
    {
        var employee = manager.GetEmployee(id);
        if (employee is null) return NotFound();

        return View(new EditEmployeeViewModel
        {
            Id = employee.Id,
            No = employee.No ?? "",
            Position = employee.Position,
            Salary = employee.Salary
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Edit(EditEmployeeViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            manager.EditEmployee(model.Id, model.Position, model.Salary);
            TempData["SuccessMessage"] = "Employee updated successfully.";
            return RedirectToAction(nameof(Index));
        }
        catch (BusinessRuleException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return View(model);
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Delete(int id)
    {
        try
        {
            manager.RemoveEmployee(id);
            TempData["SuccessMessage"] = "Employee deleted successfully.";
        }
        catch (BusinessRuleException exception)
        {
            TempData["ErrorMessage"] = exception.Message;
        }
        return RedirectToAction(nameof(Index));
    }

    private void SetDepartments() => ViewBag.Departments = new SelectList(
        manager.GetDepartments(), "Id", "Name");
}
