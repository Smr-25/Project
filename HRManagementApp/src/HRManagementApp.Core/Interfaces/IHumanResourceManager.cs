using System.Collections.Generic;
using HRManagementApp.Core.Entities;

namespace HRManagementApp.Core.Interfaces;

public interface IHumanResourceManager
{
    void AddDepartment(string name, int workerLimit, decimal salaryLimit);
    List<Department> GetDepartments();
    Department? GetDepartment(int id);
    void EditDepartment(int id, string newName);
    void RemoveDepartment(int id);
    List<Department> SearchDepartments(string query);

    void AddEmployee(string fullName, string position, decimal salary, int departmentId);
    Employee? GetEmployee(int id);
    void RemoveEmployee(int id);
    void EditEmployee(int id, string position, decimal salary);
    List<Employee> GetEmployees();
    List<Employee> Search(string query);
}
