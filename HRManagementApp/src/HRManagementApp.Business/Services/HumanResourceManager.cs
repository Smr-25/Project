using System.Data;
using HRManagementApp.Core.Entities;
using HRManagementApp.Core.Interfaces;
using HRManagementApp.DataAccess.Context;
using Microsoft.EntityFrameworkCore;

namespace HRManagementApp.Business.Services;

public class HumanResourceManager(AppDbContext context) : IHumanResourceManager
{
    public List<Department> GetDepartments() => context.Departments
        .AsNoTracking()
        .Include(department => department.Employees)
        .OrderBy(department => department.Name)
        .ToList();

    public Department? GetDepartment(int id) => context.Departments
        .AsNoTracking()
        .Include(department => department.Employees)
        .FirstOrDefault(department => department.Id == id);

    public List<Department> SearchDepartments(string query)
    {
        if (string.IsNullOrWhiteSpace(query)) return GetDepartments();

        var pattern = $"%{query.Trim()}%";
        return context.Departments.AsNoTracking()
            .Include(department => department.Employees)
            .Where(department => EF.Functions.ILike(department.Name, pattern))
            .OrderBy(department => department.Name)
            .ToList();
    }

    public void AddDepartment(string name, int workerLimit, decimal salaryLimit)
    {
        name = ValidateDepartment(name, workerLimit, salaryLimit);
        if (context.Departments.Any(department => department.Name == name))
            throw new BusinessRuleException("A department with this name already exists.");

        context.Departments.Add(new Department
        {
            Name = name,
            WorkerLimit = workerLimit,
            SalaryLimit = salaryLimit
        });
        context.SaveChanges();
    }

    public void EditDepartment(int id, string newName)
    {
        newName = newName?.Trim() ?? "";
        if (newName.Length is < 2 or > 100)
            throw new BusinessRuleException("Department name must be between 2 and 100 characters.");

        var department = context.Departments.Find(id)
            ?? throw new BusinessRuleException("Department not found.");
        if (context.Departments.Any(other => other.Id != id && other.Name == newName))
            throw new BusinessRuleException("A department with this name already exists.");

        department.Name = newName;
        context.SaveChanges();
    }

    public void RemoveDepartment(int id)
    {
        var department = context.Departments.Find(id)
            ?? throw new BusinessRuleException("Department not found.");
        context.Departments.Remove(department);
        context.SaveChanges();
    }

    public List<Employee> GetEmployees() => context.Employees
        .AsNoTracking()
        .Include(employee => employee.Department)
        .OrderBy(employee => employee.Id)
        .ToList();

    public Employee? GetEmployee(int id) => context.Employees
        .AsNoTracking()
        .Include(employee => employee.Department)
        .FirstOrDefault(employee => employee.Id == id);

    public List<Employee> Search(string query)
    {
        if (string.IsNullOrWhiteSpace(query)) return GetEmployees();

        var pattern = $"%{query.Trim()}%";
        return context.Employees.AsNoTracking()
            .Include(employee => employee.Department)
            .Where(employee => EF.Functions.ILike(employee.FullName, pattern)
                || EF.Functions.ILike(employee.No ?? "", pattern)
                || EF.Functions.ILike(employee.Position, pattern)
                || EF.Functions.ILike(employee.Department.Name, pattern))
            .OrderBy(employee => employee.Id)
            .ToList();
    }

    public void AddEmployee(string fullName, string position, decimal salary, int departmentId)
    {
        ValidateEmployee(fullName, position, salary);
        using var transaction = context.Database.BeginTransaction(IsolationLevel.Serializable);

        var department = context.Departments
            .Include(item => item.Employees)
            .FirstOrDefault(item => item.Id == departmentId)
            ?? throw new BusinessRuleException("Select an existing department.");

        if (!DepartmentPolicy.HasAvailablePosition(department))
            throw new BusinessRuleException("The department worker limit has been reached.");
        if (!DepartmentPolicy.FitsSalaryBudget(department, salary))
            throw new BusinessRuleException("The department salary budget would be exceeded.");

        var employee = new Employee
        {
            FullName = fullName.Trim(),
            Position = position.Trim(),
            Salary = salary,
            DepartmentId = departmentId
        };
        context.Employees.Add(employee);
        context.SaveChanges();

        var prefix = new string(department.Name
            .Where(char.IsLetterOrDigit)
            .Take(2)
            .ToArray()).ToUpperInvariant();
        employee.No = $"{(prefix.Length == 0 ? "EM" : prefix)}{employee.Id + 1000}";
        context.SaveChanges();
        transaction.Commit();
    }

    public void EditEmployee(int id, string position, decimal salary)
    {
        ValidatePositionAndSalary(position, salary);
        using var transaction = context.Database.BeginTransaction(IsolationLevel.Serializable);

        var employee = context.Employees
            .Include(item => item.Department)
            .ThenInclude(department => department.Employees)
            .FirstOrDefault(item => item.Id == id)
            ?? throw new BusinessRuleException("Employee not found.");

        if (!DepartmentPolicy.FitsSalaryBudget(employee.Department, salary, employee.Salary))
            throw new BusinessRuleException("The department salary budget would be exceeded.");

        employee.Position = position.Trim();
        employee.Salary = salary;
        context.SaveChanges();
        transaction.Commit();
    }

    public void RemoveEmployee(int id)
    {
        var employee = context.Employees.Find(id)
            ?? throw new BusinessRuleException("Employee not found.");
        context.Employees.Remove(employee);
        context.SaveChanges();
    }

    private static string ValidateDepartment(string? name, int workerLimit, decimal salaryLimit)
    {
        name = name?.Trim() ?? "";
        if (name.Length is < 2 or > 100)
            throw new BusinessRuleException("Department name must be between 2 and 100 characters.");
        if (workerLimit < 1)
            throw new BusinessRuleException("Worker limit must be at least one.");
        if (salaryLimit < 250)
            throw new BusinessRuleException("Salary limit must be at least 250 AZN.");
        return name;
    }

    private static void ValidateEmployee(string? fullName, string? position, decimal salary)
    {
        if (string.IsNullOrWhiteSpace(fullName) || fullName.Length > 150)
            throw new BusinessRuleException("Employee name is required and must be at most 150 characters.");
        ValidatePositionAndSalary(position, salary);
    }

    private static void ValidatePositionAndSalary(string? position, decimal salary)
    {
        if (string.IsNullOrWhiteSpace(position) || position.Trim().Length is < 2 or > 100)
            throw new BusinessRuleException("Position must be between 2 and 100 characters.");
        if (salary < 250)
            throw new BusinessRuleException("Salary must be at least 250 AZN.");
    }
}
