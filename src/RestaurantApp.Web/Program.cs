using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using RestaurantApp.Application.Security;
using RestaurantApp.Infrastructure.Data;
using RestaurantApp.Infrastructure.Identity;
using RestaurantApp.Web.Infrastructure;
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.Mac.json", optional: true, reloadOnChange: true);

// Add services to the container.
builder.Services.AddControllersWithViews(options =>
    options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()));
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

builder.Services.AddDbContext<RestaurantDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services
    .AddIdentity<ApplicationUser, IdentityRole>(options =>
    {
        options.Password.RequiredLength = 12;
        options.Password.RequireDigit = true;
        options.Password.RequireLowercase = true;
        options.Password.RequireUppercase = true;
        options.Password.RequireNonAlphanumeric = true;
        options.Lockout.MaxFailedAccessAttempts = 5;
        options.User.RequireUniqueEmail = true;
    })
    .AddEntityFrameworkStores<RestaurantApp.Infrastructure.Data.RestaurantDbContext>()
    .AddDefaultTokenProviders();

builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Account/Login";
    options.AccessDeniedPath = "/Account/AccessDenied";
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.SlidingExpiration = true;
    options.ExpireTimeSpan = TimeSpan.FromHours(8);
});

builder.Services.AddScoped(typeof(RestaurantApp.Application.Abstractions.IRepository<>), typeof(RestaurantApp.Infrastructure.Repositories.Concretes.Repository<>));
builder.Services.AddScoped<RestaurantApp.Application.Abstractions.IUnitOfWork, EfUnitOfWork>();
builder.Services.AddScoped<RestaurantApp.Application.Interfaces.ICategoryService, RestaurantApp.Application.Services.CategoryService>();
builder.Services.AddScoped<RestaurantApp.Application.Interfaces.IMenuItemService, RestaurantApp.Application.Services.MenuItemService>();
builder.Services.AddScoped<RestaurantApp.Application.Interfaces.IOrderService, RestaurantApp.Application.Services.OrderService>();
builder.Services.AddScoped<RestaurantApp.Application.Interfaces.IDiningTableService, RestaurantApp.Application.Services.DiningTableService>();

var app = builder.Build();

await using (var scope = app.Services.CreateAsyncScope())
{
    var services = scope.ServiceProvider;
    await DatabaseInitializer.InitializeAsync(services.GetRequiredService<RestaurantDbContext>());
    await IdentitySeeder.SeedAsync(
        services.GetRequiredService<RoleManager<IdentityRole>>(),
        services.GetRequiredService<UserManager<ApplicationUser>>(),
        RestaurantRoles.All,
        builder.Configuration["BootstrapAdmin:Email"],
        builder.Configuration["BootstrapAdmin:Password"],
        builder.Configuration["BootstrapAdmin:DisplayName"]);
}

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler();
    app.UseHsts();
}
else
{
    app.UseDeveloperExceptionPage();
}

app.UseMiddleware<SecurityHeadersMiddleware>();
app.UseHttpsRedirection();
app.UseRouting();
app.UseStatusCodePagesWithReExecute("/Home/ErrorStatus", "?code={0}");

app.UseAuthentication();
app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();
