using RestaurantApp.Domain.Common;
using System.Collections.Generic;
namespace RestaurantApp.Domain.Models
{
    public class Order : BaseEntity
    {
        public string Number { get; private set; } = string.Empty;
        public decimal TotalAmount { get; private set; }
        public OrderStatus Status { get; private set; } = OrderStatus.Pending;
        public string? Notes { get; private set; }
        public string? CancellationReason { get; private set; }
        public DateTimeOffset? CancelledAtUtc { get; private set; }
        public int? DiningTableId { get; private set; }
        public DiningTable? DiningTable { get; private set; }
        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();

        private Order()
        {
        }

        public static Order Create(string number, int? diningTableId = null, string? notes = null)
        {
            if (string.IsNullOrWhiteSpace(number))
            {
                throw new ArgumentException("An order number is required.", nameof(number));
            }

            return new Order
            {
                Number = number.Trim(),
                DiningTableId = diningTableId,
                Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim()
            };
        }

        public void AddItem(MenuItem menuItem, int quantity, string? specialInstructions = null)
        {
            ArgumentNullException.ThrowIfNull(menuItem);
            if (quantity <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(quantity), "Quantity must be greater than zero.");
            }

            if (!menuItem.IsAvailable)
            {
                throw new InvalidOperationException($"{menuItem.Name} is not currently available.");
            }

            var normalizedInstructions = Normalize(specialInstructions);
            var existingItem = OrderItems.FirstOrDefault(item =>
                item.MenuItemId == menuItem.Id && item.SpecialInstructions == normalizedInstructions);

            if (existingItem is null)
            {
                OrderItems.Add(OrderItem.Create(menuItem, quantity, normalizedInstructions));
            }
            else
            {
                existingItem.IncreaseQuantity(quantity);
            }

            RecalculateTotal();
        }

        public void MoveTo(OrderStatus nextStatus)
        {
            if (!Status.CanTransitionTo(nextStatus))
            {
                throw new InvalidOperationException($"Order cannot move from {Status} to {nextStatus}.");
            }

            Status = nextStatus;
            UpdatedAtUtc = DateTimeOffset.UtcNow;
        }

        public void Cancel(string reason)
        {
            if (Status is OrderStatus.Served or OrderStatus.Cancelled)
            {
                throw new InvalidOperationException("A served or cancelled order cannot be cancelled.");
            }

            if (string.IsNullOrWhiteSpace(reason))
            {
                throw new ArgumentException("A cancellation reason is required.", nameof(reason));
            }

            Status = OrderStatus.Cancelled;
            CancellationReason = reason.Trim();
            CancelledAtUtc = DateTimeOffset.UtcNow;
            UpdatedAtUtc = DateTimeOffset.UtcNow;
        }

        private void RecalculateTotal()
        {
            TotalAmount = OrderItems.Sum(item => item.UnitPrice * item.Quantity);
            UpdatedAtUtc = DateTimeOffset.UtcNow;
        }

        private static string? Normalize(string? value) =>
            string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
