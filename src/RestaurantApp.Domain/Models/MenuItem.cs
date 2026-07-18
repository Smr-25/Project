using RestaurantApp.Domain.Common;
using System.Collections.Generic;
namespace RestaurantApp.Domain.Models
{
    public class MenuItem : BaseEntity
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsAvailable { get; set; } = true;
        public int CategoryId { get; set; }
        public Category Category { get; set; } = null!;
        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}
