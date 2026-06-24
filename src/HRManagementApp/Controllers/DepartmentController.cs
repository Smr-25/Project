using System.Linq;
using Microsoft.AspNetCore.Mvc;
using HRManagementApp.Core.Interfaces;
using HRManagementApp.Business.DTOs;
using HRManagementApp.Models;

namespace HRManagementApp.Controllers;

public class DepartmentController(IHumanResourceManager manager) : Controller
{
    public IActionResult Index(string search = null)
    {
        ViewData["SearchQuery"] = search;

        var departments = string.IsNullOrWhiteSpace(search) 
            ? manager.GetDepartments() 
            : manager.SearchDepartments(search);
            
        return View(departments);
    }

    [HttpGet]
    public IActionResult Create()
    {
        return View(new DepartmentDto());
    }

    [HttpPost]
    public IActionResult Create(DepartmentDto dto)
    {
        if (!ModelState.IsValid)
        {
            return View(dto);
        }

        try
        {
            manager.AddDepartment(dto.Name, dto.WorkerLimit, dto.SalaryLimit);
            TempData["SuccessMessage"] = "Department created successfully!";
            return RedirectToAction(nameof(Index));
        }
        catch (System.Exception ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(dto);
        }
    }

    [HttpGet]
    public IActionResult Edit(string name)
    {
        if (string.IsNullOrEmpty(name)) return BadRequest();

        var dept = manager.GetDepartments().FirstOrDefault(d => d.Name.Equals(name, System.StringComparison.OrdinalIgnoreCase));
        if (dept == null)
        {
            return NotFound();
        }

        var model = new EditDepartmentViewModel
        {
            OldName = dept.Name,
            NewName = dept.Name
        };

        return View(model);
    }

    [HttpPost]
    public IActionResult Edit(EditDepartmentViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            manager.EditDepartments(model.OldName, model.NewName);
            TempData["SuccessMessage"] = $"Department name updated to: {model.NewName}";
            return RedirectToAction(nameof(Index));
        }
        catch (System.Exception ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(model);
        }
    }

    [HttpPost]
    public IActionResult Delete(string name)
    {
        try
        {
            manager.RemoveDepartment(name);
            TempData["SuccessMessage"] = "Department deleted successfully!";
        }
        catch (System.Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }
        
        return RedirectToAction(nameof(Index));
    }
}
