using FluentValidation;
using HRManagementApp.Business.DTOs;

namespace HRManagementApp.Business.Validators;

public class EmployeeDtoValidator : AbstractValidator<EmployeeDto>
{
    public EmployeeDtoValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Employee full name cannot be empty.");

        RuleFor(x => x.Position)
            .NotEmpty().WithMessage("Employee position cannot be empty.")
            .MinimumLength(2).WithMessage("Position name must be at least 2 characters long.");

        RuleFor(x => x.Salary)
            .GreaterThanOrEqualTo(250).WithMessage("Employee salary cannot be less than 250.");

        RuleFor(x => x.DepartmentName)
            .NotEmpty().WithMessage("Department name must be specified.");
    }
}
