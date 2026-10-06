using RestaurantApp.Domain.Common;

namespace RestaurantApp.Infrastructure.Repositories.Concretes
{
    public class Repository<T>(RestaurantDbContext context) : IRepository<T>
        where T : BaseEntity
    {
        private DbSet<T> Table => context.Set<T>();
        public IQueryable<T> GetAllAsync(Expression<Func<T, bool>>? expression = null, params string[]? includes)
        {
            var query = Table.AsQueryable();
            if (includes != null)
            {
                foreach (var include in includes)
                {
                    query = query.Include(include);
                }
            }
            if (expression != null)
            {
                query = query.Where(expression);
            }
            return query;
        }
        public IQueryable<T> GetAllAsync(Expression<Func<T, bool>>? expression = null, params Expression<Func<T, object>>[]? includes)
        {
            var query = Table.AsQueryable();
            if (includes != null)
            {
                foreach (var include in includes)
                {
                    query = query.Include(include);
                }
            }
            if (expression != null)
            {
                query = query.Where(expression);
            }
            return query;
        }
        public async Task<T?> GetAsync(Expression<Func<T, bool>> expression, params string[]? includes)
        {
            var query = Table.AsQueryable();
            if (includes != null)
            {
                foreach (string include in includes)
                {
                    query = query.Include(include);
                }
            }
            return await query.FirstOrDefaultAsync(expression);
        }
        public async Task<T?> GetAsync(Expression<Func<T, bool>> expression, params Expression<Func<T, object>>[] includes)
        {
            var query = Table.AsQueryable();
            if (includes != null)
            {
                foreach (var include in includes)
                {
                    query = query.Include(include);
                }
            }
            return await query.FirstOrDefaultAsync(expression);
        }
        public async Task<T?> GetByIdAsync(int id, params string[]? includes)
        {
            var query = Table.AsQueryable();
            if (includes != null)
            {
                foreach (string include in includes)
                {
                    query = query.Include(include);
                }
            }
            return await query.FirstOrDefaultAsync(x => x.Id == id);
        }
        public async Task<T?> GetByIdAsync(int id, params Expression<Func<T, object>>[] includes)
        {
            var query = Table.AsQueryable();
            if (includes != null)
            {
                foreach (var include in includes)
                {
                    query = query.Include(include);
                }
            }
            return await query.FirstOrDefaultAsync(x => x.Id == id);
        }
        public async Task AddAsync(T entity)
        {
            await Table.AddAsync(entity);
        }
        public void Remove(T entity)
        {
            Table.Remove(entity);
        }
        public void Update(T entity)
        {
            Table.Update(entity);
        }
        public Task UpdateAsync(T entity)
        {
            Table.Update(entity);
            return Task.CompletedTask;
        }
        public Task RemoveAsync(T entity)
        {
            Table.Remove(entity);
            return Task.CompletedTask;
        }
        public async Task<int> SaveChangesAsync()
        {
            return await context.SaveChangesAsync();
        }
        public async Task<bool> IsExistAsync(Expression<Func<T, bool>> expression)
        {
            return await Table.AnyAsync(expression);
        }
        public async Task<int> CommitAsync()
        {
            return await context.SaveChangesAsync();
        }
    }
}
