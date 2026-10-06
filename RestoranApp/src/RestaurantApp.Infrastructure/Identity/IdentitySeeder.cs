using Microsoft.AspNetCore.Identity;

namespace RestaurantApp.Infrastructure.Identity;

public static class IdentitySeeder
{
    public static async Task SeedAsync(
        RoleManager<IdentityRole> roleManager,
        UserManager<ApplicationUser> userManager,
        IReadOnlyCollection<string> roles,
        string? adminEmail,
        string? adminPassword,
        string? adminDisplayName)
    {
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                var roleResult = await roleManager.CreateAsync(new IdentityRole(role));
                EnsureSucceeded(roleResult, $"create the {role} role");
            }
        }

        if (string.IsNullOrWhiteSpace(adminEmail) || string.IsNullOrWhiteSpace(adminPassword))
        {
            return;
        }

        var normalizedEmail = adminEmail.Trim();
        var user = await userManager.FindByEmailAsync(normalizedEmail);
        if (user is null)
        {
            user = new ApplicationUser
            {
                UserName = normalizedEmail,
                Email = normalizedEmail,
                EmailConfirmed = true,
                DisplayName = string.IsNullOrWhiteSpace(adminDisplayName)
                    ? "Restaurant administrator"
                    : adminDisplayName.Trim()
            };

            EnsureSucceeded(
                await userManager.CreateAsync(user, adminPassword),
                "create the configured administrator");
        }

        if (!await userManager.IsInRoleAsync(user, RestaurantApp.Application.Security.RestaurantRoles.Admin))
        {
            EnsureSucceeded(
                await userManager.AddToRoleAsync(user, RestaurantApp.Application.Security.RestaurantRoles.Admin),
                "assign the administrator role");
        }
    }

    private static void EnsureSucceeded(IdentityResult result, string action)
    {
        if (result.Succeeded)
        {
            return;
        }

        var details = string.Join("; ", result.Errors.Select(error => error.Description));
        throw new InvalidOperationException($"Could not {action}: {details}");
    }
}
