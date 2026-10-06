using RestaurantApp.Application.Abstractions;
using RestaurantApp.Application.Dtos.MenuItems;
using RestaurantApp.Application.Exceptions;
using RestaurantApp.Application.Services;
using RestaurantApp.Domain.Common;
using RestaurantApp.Domain.Models;

namespace RestaurantApp.UnitTests;

public sealed class MenuItemServiceTests
{
    [Fact]
    public async Task Add_rejects_a_duplicate_name()
    {
        var items = new FakeRepository<MenuItem>(
            new MenuItem { Id = 1, Name = "Tiramisu", Description = "Classic dessert item.", Price = 8m, CategoryId = 1 });
        var categories = new FakeRepository<Category>(new Category { Id = 1, Name = "Desserts", IsActive = true });
        var service = new MenuItemService(items, categories);

        await Assert.ThrowsAsync<EntityAlreadyExistException>(() => service.AddAsync(new MenuItemCreateDto
        {
            Name = " tiramisu ",
            Description = "Another dessert description.",
            Price = 9m,
            CategoryId = 1
        }));
    }

    [Fact]
    public async Task Add_rejects_an_archived_category()
    {
        var items = new FakeRepository<MenuItem>();
        var categories = new FakeRepository<Category>(new Category { Id = 3, Name = "Seasonal", IsActive = false });
        var service = new MenuItemService(items, categories);

        await Assert.ThrowsAsync<EntityNotFoundException>(() => service.AddAsync(new MenuItemCreateDto
        {
            Name = "Summer plate",
            Description = "A seasonal menu item description.",
            Price = 14m,
            CategoryId = 3
        }));
    }
}

internal sealed class FakeRepository<T>(params T[] seed) : IRepository<T> where T : BaseEntity
{
    private readonly List<T> _items = [.. seed];

    public IQueryable<T> GetAllAsync(
        System.Linq.Expressions.Expression<Func<T, bool>>? expression = null,
        params string[]? includes) => expression is null ? _items.AsQueryable() : _items.AsQueryable().Where(expression);

    public IQueryable<T> GetAllAsync(
        System.Linq.Expressions.Expression<Func<T, bool>>? expression = null,
        params System.Linq.Expressions.Expression<Func<T, object>>[] includes) =>
        expression is null ? _items.AsQueryable() : _items.AsQueryable().Where(expression);

    public Task<T?> GetAsync(System.Linq.Expressions.Expression<Func<T, bool>> expression, params string[]? includes) =>
        Task.FromResult(_items.AsQueryable().FirstOrDefault(expression));

    public Task<T?> GetAsync(
        System.Linq.Expressions.Expression<Func<T, bool>> expression,
        params System.Linq.Expressions.Expression<Func<T, object>>[] includes) => GetAsync(expression, Array.Empty<string>());

    public Task<T?> GetByIdAsync(int id, params string[]? includes) => Task.FromResult(_items.FirstOrDefault(item => item.Id == id));
    public Task<T?> GetByIdAsync(int id, params System.Linq.Expressions.Expression<Func<T, object>>[] includes) => GetByIdAsync(id, Array.Empty<string>());
    public Task AddAsync(T entity) { _items.Add(entity); return Task.CompletedTask; }
    public void Remove(T entity) => _items.Remove(entity);
    public Task RemoveAsync(T entity) { Remove(entity); return Task.CompletedTask; }
    public void Update(T entity) { }
    public Task UpdateAsync(T entity) => Task.CompletedTask;
    public Task<int> CommitAsync() => Task.FromResult(0);
    public Task<int> SaveChangesAsync() => Task.FromResult(0);
    public Task<bool> IsExistAsync(System.Linq.Expressions.Expression<Func<T, bool>> expression) =>
        Task.FromResult(_items.AsQueryable().Any(expression));
}
