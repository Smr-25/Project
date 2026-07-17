using RestaurantApp.Domain.Common;
using System;
using System.Collections.Generic;
namespace RestaurantApp.Domain.Models
{
    public class Order : BaseEntity
    {
        public decimal TotalAmount { get; set; }
        public DateTime Date { get; set; } = DateTime.UtcNow;
        public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}
