using FluentValidation;
using HRManagementApp.Business.DTOs;
using HRManagementApp.Business.Services;
using HRManagementApp.Core.Interfaces;
using HRManagementApp.Models;
using Microsoft.AspNetCore.Mvc;

namespace HRManagementApp.Controllers;

public class DepartmentController(
    IHumanResourceManager manager,
    IValidator<DepartmentDto> validator) : Controller
{
    public IActionResult Index(string? search)
    {
        ViewData["SearchQuery"] = search;
        var departments = string.IsNullOrWhiteSpace(search)
            ? manager.GetDepartments()
            : manager.SearchDepartments(search);
        return View(departments);
    }

    [HttpGet]
    public IActionResult Create() => View(new DepartmentDto());

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Create(DepartmentDto dto)
    {
        var validation = validator.Validate(dto);
        foreach (var error in validation.Errors)
            ModelState.AddModelError(error.PropertyName, error.ErrorMessage);
        if (!ModelState.IsValid) return View(dto);

        try
        {
            manager.AddDepartment(dto.Name, dto.WorkerLimit, dto.SalaryLimit);
            TempData["SuccessMessage"] = "Department created successfully.";
            return RedirectToAction(nameof(Index));
        }
        catch (BusinessRuleException exception)
        {
            ModelState.AddModelError(string.Empty, exception.Message);
            return View(dto);
        }
    }

    [HttpGet]
    public IActionResult Edit(int id)
    {
        var department = manager.GetDepartment(id);
        if (department is null) return NotFound();

        return View(new EditDepartmentViewModel
        {
            Id = department.Id,
            OldName = department.Name,
            NewName = department.Name
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public IActionResult Edit(EditDepartmentViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            manager.EditDepartment(model.Id, model.NewName);
            TempData["SuccessMessage"] = "Department name updated successfully.";
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
            manager.RemoveDepartment(id);
            TempData["SuccessMessage"] = "Department deleted successfully.";
        }
        catch (BusinessRuleException exception)
        {
            TempData["ErrorMessage"] = exception.Message;
        }
        return RedirectToAction(nameof(Index));
    }
}
