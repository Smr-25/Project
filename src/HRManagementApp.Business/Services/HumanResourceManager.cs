using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using HRManagementApp.Core.Entities;
using HRManagementApp.Core.Interfaces;
using HRManagementApp.DataAccess.Context;

namespace HRManagementApp.Business.Services;

public class HumanResourceManager(AppDbContext context) : IHumanResourceManager
{
    public List<Department> Departments => context.Departments.Include(d => d.Employees).ToList();

    public void AddDepartment(string name, int workerLimit, double salaryLimit)
    {
        if (context.Departments.Any(d => d.Name.ToLower() == name.ToLower()))
            throw new Exception("Department with this name already exists!");

        var department = new Department
        {
            Name = name,
            WorkerLimit = workerLimit,
            SalaryLimit = salaryLimit
        };

        context.Departments.Add(department);
        context.SaveChanges();
    }

    public List<Department> GetDepartments()
    {
        return Departments;
    }

    public void EditDepartments(string oldName, string newName)
    {
        var department = context.Departments.Include(d => d.Employees)
            .FirstOrDefault(d => d.Name.ToLower() == oldName.ToLower());
            
        if (department == null)
            throw new Exception("Department not found!");
            
        if (!oldName.Equals(newName, StringComparison.OrdinalIgnoreCase) && 
            context.Departments.Any(d => d.Name.ToLower() == newName.ToLower()))
            throw new Exception("Department with this new name already exists!");

        if (!oldName.Equals(newName, StringComparison.OrdinalIgnoreCase))
        {
            var newDept = new Department
            {
                Name = newName,
                WorkerLimit = department.WorkerLimit,
                SalaryLimit = department.SalaryLimit
            };
            
            context.Departments.Add(newDept);
            
            foreach (var emp in department.Employees.ToList())
            {
                emp.DepartmentName = newName;
            }
            
            context.Departments.Remove(department);
            context.SaveChanges();
        }
    }

    public void RemoveDepartment(string name)
    {
        var department = context.Departments.FirstOrDefault(d => d.Name.ToLower() == name.ToLower());
        if (department == null)
            throw new Exception("Department not found!");

        context.Departments.Remove(department);
        context.SaveChanges();
    }

    public List<Department> SearchDepartments(string query)
    {
        if (string.IsNullOrWhiteSpace(query))
            return context.Departments.Include(d => d.Employees).ToList();

        query = query.ToLower();
        return context.Departments.Include(d => d.Employees)
            .Where(d => d.Name.ToLower().Contains(query))
            .ToList();
    }

    public void AddEmployee(string fullName, string position, double salary, string departmentName)
    {
        var department = context.Departments.Include(d => d.Employees)
            .FirstOrDefault(d => d.Name.ToLower() == departmentName.ToLower());
            
        if (department == null)
            throw new Exception("Specified department not found!");

        if (department.Employees.Count >= department.WorkerLimit)
            throw new Exception("Worker limit in the department has been reached!");

        if (department.Employees.Sum(e => e.Salary) + salary > department.SalaryLimit)
            throw new Exception("Department salary limit has been exceeded!");

        int currentTotalEmployees = context.Employees.Count() + 1000 + 1;
        
        string prefix = department.Name.Length >= 2 
            ? department.Name.Substring(0, 2).ToUpper() 
            : department.Name.ToUpper();
            
        string employeeNo = $"{prefix}{currentTotalEmployees}";

        var employee = new Employee
        {
            No = employeeNo,
            FullName = fullName,
            Position = position,
            Salary = salary,
            DepartmentName = department.Name
        };

        context.Employees.Add(employee);
        context.SaveChanges();
    }

    public void RemoveEmployee(string no, string departmentName)
    {
        var employee = context.Employees.FirstOrDefault(e => 
            e.No.ToLower() == no.ToLower() && 
            e.DepartmentName.ToLower() == departmentName.ToLower());
            
        if (employee == null)
            throw new Exception("Employee not found in the specified department!");

        context.Employees.Remove(employee);
        context.SaveChanges();
    }

    public void EditEmployee(string no, string position, double salary)
    {
        var employee = context.Employees.FirstOrDefault(e => e.No.ToLower() == no.ToLower());
        if (employee == null)
            throw new Exception("Employee with the specified number not found!");

        if (salary != employee.Salary)
        {
            var department = context.Departments.Include(d => d.Employees)
                .First(d => d.Name == employee.DepartmentName);
                
            double newTotalSalary = department.Employees.Sum(e => e.Salary) - employee.Salary + salary;
            if (newTotalSalary > department.SalaryLimit)
                throw new Exception("Salary increase exceeds the department's salary limit!");
        }
        
        employee.Position = position;
        employee.Salary = salary;
        context.SaveChanges();
    }

    public List<Employee> Search(string query)
    {
        if (string.IsNullOrWhiteSpace(query))
            return new List<Employee>();

        query = query.ToLower();
        return context.Employees
            .Where(e => e.FullName.ToLower().Contains(query) || 
                        e.No.ToLower().Contains(query) || 
                        e.Position.ToLower().Contains(query) || 
                        e.DepartmentName.ToLower().Contains(query))
            .ToList();
    }
}
