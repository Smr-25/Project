using RestaurantApp.Domain.Common;

namespace RestaurantApp.Domain.Models;

public class DiningTable : BaseEntity
{
    public string Number { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public bool IsActive { get; set; } = true;
    public ICollection<Order> Orders { get; set; } = new List<Order>();
}
