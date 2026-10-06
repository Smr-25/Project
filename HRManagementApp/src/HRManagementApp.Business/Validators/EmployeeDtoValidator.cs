using FluentValidation;
using HRManagementApp.Business.DTOs;

namespace HRManagementApp.Business.Validators;

public class EmployeeDtoValidator : AbstractValidator<EmployeeDto>
{
    public EmployeeDtoValidator()
    {
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Employee full name cannot be empty.")
            .MaximumLength(150);

        RuleFor(x => x.Position)
            .NotEmpty().WithMessage("Employee position cannot be empty.")
            .MinimumLength(2).WithMessage("Position name must be at least 2 characters long.")
            .MaximumLength(100);

        RuleFor(x => x.Salary)
            .GreaterThanOrEqualTo(250).WithMessage("Employee salary cannot be less than 250.");

        RuleFor(x => x.DepartmentId)
            .GreaterThan(0).WithMessage("Select a department.");
    }
}
