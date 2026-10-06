using RestaurantApp.Domain.Common;
namespace RestaurantApp.Domain.Models
{
    public class OrderItem : BaseEntity
    {
        public int Quantity { get; private set; }
        public decimal UnitPrice { get; private set; }
        public string? SpecialInstructions { get; private set; }
        public int MenuItemId { get; private set; }
        public MenuItem MenuItem { get; private set; } = null!;
        public int OrderId { get; private set; }
        public Order Order { get; private set; } = null!;

        private OrderItem()
        {
        }

        internal static OrderItem Create(MenuItem menuItem, int quantity, string? specialInstructions) => new()
        {
            MenuItemId = menuItem.Id,
            MenuItem = menuItem,
            Quantity = quantity,
            UnitPrice = menuItem.Price,
            SpecialInstructions = string.IsNullOrWhiteSpace(specialInstructions)
                ? null
                : specialInstructions.Trim()
        };

        internal void IncreaseQuantity(int amount)
        {
            if (amount <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(amount));
            }

            Quantity += amount;
            UpdatedAtUtc = DateTimeOffset.UtcNow;
        }
    }
}
