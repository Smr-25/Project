using System.Linq.Expressions;
using RestaurantApp.Domain.Common;
namespace RestaurantApp.Application.Abstractions;
public interface IRepository<T> where T : BaseEntity
{
    IQueryable<T> GetAllAsync(Expression<Func<T, bool>>? expression = null, params string[]? includes);
    IQueryable<T> GetAllAsync(Expression<Func<T, bool>>? expression = null, params Expression<Func<T, object>>[] includes);
    Task<T?> GetAsync(Expression<Func<T, bool>> expression, params string[]? includes);
    Task<T?> GetAsync(Expression<Func<T, bool>> expression, params Expression<Func<T, object>>[] includes);
    Task<T?> GetByIdAsync(int id, params string[]? includes);
    Task<T?> GetByIdAsync(int id, params Expression<Func<T, object>>[] includes);
    Task AddAsync(T entity);
    void Remove(T entity);
    Task RemoveAsync(T entity);
    void Update(T entity);
    Task UpdateAsync(T entity);
    Task<int> CommitAsync();
    Task<int> SaveChangesAsync();
    Task<bool> IsExistAsync(Expression<Func<T, bool>> expression);
}
