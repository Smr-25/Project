using System.ComponentModel.DataAnnotations;

namespace HRManagementApp.Models;

public class EditEmployeeViewModel
{
    public int Id { get; set; }
    public string No { get; set; } = null!;
    
    [Required(ErrorMessage = "Position is required.")]
    [MinLength(2, ErrorMessage = "Position must be at least 2 characters long.")]
    public string Position { get; set; } = null!;
    
    [Required(ErrorMessage = "Salary is required.")]
    [Range(typeof(decimal), "250", "1000000000", ErrorMessage = "Salary cannot be less than 250.")]
    public decimal Salary { get; set; }
}
