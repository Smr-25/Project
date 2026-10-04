namespace HRManagementApp.Core.Entities;

public class Department
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public int WorkerLimit { get; set; }
    public decimal SalaryLimit { get; set; }
    public List<Employee> Employees { get; set; } = [];

    public decimal CalcSalaryAverage()
    {
        if (Employees.Count == 0)
            return 0;

        return Employees.Average(e => e.Salary);
    }
}
