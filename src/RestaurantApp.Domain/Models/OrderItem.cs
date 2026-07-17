using RestaurantApp.Domain.Common;
namespace RestaurantApp.Domain.Models
{
    public class OrderItem : BaseEntity
    {
        public int Count { get; set; }
        public decimal Price { get; set; } 
        public int MenuItemId { get; set; }
        public MenuItem MenuItem { get; set; } = null!;
        public int OrderId { get; set; }
        public Order Order { get; set; } = null!;
    }
}
