using HRManagementApp.Business.DTOs;
using HRManagementApp.Business.Validators;

namespace HRManagementApp.Tests;

public class ValidationTests
{
    [Fact]
    public void DepartmentValidator_RejectsInvalidLimits()
    {
        var result = new DepartmentDtoValidator().Validate(new DepartmentDto
        {
            Name = "I",
            WorkerLimit = 0,
            SalaryLimit = 249m
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, error => error.PropertyName == nameof(DepartmentDto.Name));
        Assert.Contains(result.Errors, error => error.PropertyName == nameof(DepartmentDto.WorkerLimit));
        Assert.Contains(result.Errors, error => error.PropertyName == nameof(DepartmentDto.SalaryLimit));
    }

    [Fact]
    public void EmployeeValidator_RequiresExistingDepartmentSelection()
    {
        var result = new EmployeeDtoValidator().Validate(new EmployeeDto
        {
            FullName = "Ada Lovelace",
            Position = "Engineer",
            Salary = 500m,
            DepartmentId = 0
        });

        Assert.False(result.IsValid);
        Assert.Contains(result.Errors, error => error.PropertyName == nameof(EmployeeDto.DepartmentId));
    }
}
