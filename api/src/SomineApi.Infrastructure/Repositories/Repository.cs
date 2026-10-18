using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application.Interfaces;
using SomineApi.Infrastructure.Data;

namespace SomineApi.Infrastructure.Repositories;

public class Repository<T> : IRepository<T> where T : class
{
    protected readonly SomineDbContext _context;
    protected readonly DbSet<T> _dbSet;

    public Repository(SomineDbContext context)
    {
        _context = context;
        _dbSet = context.Set<T>();
    }

    public async Task<T?> GetByIdAsync(Guid id) => await _dbSet.FindAsync(id);

    public async Task<IEnumerable<T>> GetAllAsync() => await _dbSet.ToListAsync();

    public async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate)
        => await _dbSet.Where(predicate).ToListAsync();

    public async Task<T> AddAsync(T entity)
    {
        await _dbSet.AddAsync(entity);
        await _context.SaveChangesAsync();
        return entity;
    }

    public async Task<IEnumerable<T>> AddRangeAsync(IEnumerable<T> entities)
    {
        await _dbSet.AddRangeAsync(entities);
        await _context.SaveChangesAsync();
        return entities;
    }

    public void Update(T entity)
    {
        _dbSet.Attach(entity);
        _context.Entry(entity).State = EntityState.Modified;
    }

    public void Remove(T entity) => _dbSet.Remove(entity);

    public void RemoveRange(IEnumerable<T> entities) => _dbSet.RemoveRange(entities);

    public async Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null)
        => predicate == null ? await _dbSet.CountAsync() : await _dbSet.CountAsync(predicate);

    public async Task<bool> AnyAsync(Expression<Func<T, bool>> predicate)
        => await _dbSet.AnyAsync(predicate);

    public IQueryable<T> Query() => _dbSet.AsQueryable();
}
