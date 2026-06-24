using System.Collections.Generic;
using System.Linq;

namespace HRManagementApp.Core.Entities;

public class Department
{
    public string Name { get; set; } = null!;
    public int WorkerLimit { get; set; }
    public double SalaryLimit { get; set; }
    public List<Employee> Employees { get; set; } = [];

    public double CalcSalaryAverage()
    {
        if (Employees.Count == 0)
            return 0;
            
        return Employees.Average(e => e.Salary);
    }
}
