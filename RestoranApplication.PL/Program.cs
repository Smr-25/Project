using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.Mac.json", optional: true, reloadOnChange: true);

// Add services to the container.
builder.Services.AddControllersWithViews();

builder.Services.AddDbContext<RestaurantApp.DDL.Data.RestaurantDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddScoped(typeof(RestaurantApp.DDL.Repositories.Interfaces.IRepository<>), typeof(RestaurantApp.DDL.Repositories.Concretes.Repository<>));
builder.Services.AddScoped<RestaurantApp.BBL.Interfaces.ICategoryService, RestaurantApp.BBL.Services.CategoryService>();
builder.Services.AddScoped<RestaurantApp.BBL.Interfaces.IMenuItemService, RestaurantApp.BBL.Services.MenuItemService>();
builder.Services.AddScoped<RestaurantApp.BBL.Interfaces.IOrderService, RestaurantApp.BBL.Services.OrderService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();
