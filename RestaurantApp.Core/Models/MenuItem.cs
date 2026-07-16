using RestaurantApp.Core.Common;
using System.Collections.Generic;
namespace RestaurantApp.Core.Models
{
    public class MenuItem : BaseEntity
    {
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public int CategoryId { get; set; }
        public Category Category { get; set; } = null!;
        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}
