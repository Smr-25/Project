using System.Collections.Generic;
using HRManagementApp.Core.Entities;

namespace HRManagementApp.Core.Interfaces;

public interface IHumanResourceManager
{
    List<Department> Departments { get; }

    void AddDepartment(string name, int workerLimit, double salaryLimit);
    List<Department> GetDepartments();
    void EditDepartments(string oldName, string newName);
    void RemoveDepartment(string name);
    List<Department> SearchDepartments(string query);

    void AddEmployee(string fullName, string position, double salary, string departmentName);
    void RemoveEmployee(string no, string departmentName);
    void EditEmployee(string no, string position, double salary);
    
    List<Employee> Search(string query);
}
