using RestaurantApp.Domain.Common;
namespace RestaurantApp.Domain.Models
{
    public class Category : BaseEntity
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int DisplayOrder { get; set; }
        public bool IsActive { get; set; } = true;
        public ICollection<MenuItem> MenuItems { get; set; } = new List<MenuItem>();
    }
}
