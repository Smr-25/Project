namespace HRManagementApp.Models;

public sealed class DashboardViewModel
{
    public int TotalDepartments { get; init; }
    public int TotalEmployees { get; init; }
    public decimal MonthlySalary { get; init; }
    public IReadOnlyList<DepartmentOverview> Departments { get; init; } = [];
}

public sealed record DepartmentOverview(
    string Name,
    int EmployeeCount,
    int WorkerLimit,
    decimal SalarySpent,
    decimal SalaryLimit);
