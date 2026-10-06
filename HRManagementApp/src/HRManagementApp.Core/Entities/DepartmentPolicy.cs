namespace HRManagementApp.Core.Entities;

public static class DepartmentPolicy
{
    public static bool HasAvailablePosition(Department department) =>
        department.Employees.Count < department.WorkerLimit;

    public static bool FitsSalaryBudget(
        Department department,
        decimal proposedSalary,
        decimal currentSalary = 0) =>
        department.Employees.Sum(employee => employee.Salary)
            - currentSalary + proposedSalary <= department.SalaryLimit;
}
