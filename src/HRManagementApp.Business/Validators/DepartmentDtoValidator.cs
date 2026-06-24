using FluentValidation;
using HRManagementApp.Business.DTOs;

namespace HRManagementApp.Business.Validators;

public class DepartmentDtoValidator : AbstractValidator<DepartmentDto>
{
    public DepartmentDtoValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Department name cannot be empty.")
            .MinimumLength(2).WithMessage("Department name must be at least 2 characters long.");

        RuleFor(x => x.WorkerLimit)
            .GreaterThanOrEqualTo(1).WithMessage("Worker limit in the department must be at least 1.");

        RuleFor(x => x.SalaryLimit)
            .GreaterThanOrEqualTo(250).WithMessage("Salary limit in the department must be at least 250.");
    }
}
