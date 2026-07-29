# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /source

COPY global.json Directory.Build.props ./
COPY src/RestaurantApp.Domain/RestaurantApp.Domain.csproj src/RestaurantApp.Domain/
COPY src/RestaurantApp.Application/RestaurantApp.Application.csproj src/RestaurantApp.Application/
COPY src/RestaurantApp.Infrastructure/RestaurantApp.Infrastructure.csproj src/RestaurantApp.Infrastructure/
COPY src/RestaurantApp.Web/RestaurantApp.Web.csproj src/RestaurantApp.Web/
RUN dotnet restore src/RestaurantApp.Web/RestaurantApp.Web.csproj

COPY src/ src/
RUN dotnet publish src/RestaurantApp.Web/RestaurantApp.Web.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/app/.aspnet/DataProtection-Keys \
    && chown -R $APP_UID:$APP_UID /home/app/.aspnet

ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

COPY --from=build --chown=$APP_UID:$APP_UID /app/publish .

USER $APP_UID
HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=5 \
    CMD curl --fail --silent http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "RestaurantApp.Web.dll"]
