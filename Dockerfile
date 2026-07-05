FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /source

COPY HRManagementApp.slnx ./
COPY src/HRManagementApp/HRManagementApp.csproj src/HRManagementApp/
COPY src/HRManagementApp.Core/HRManagementApp.Core.csproj src/HRManagementApp.Core/
COPY src/HRManagementApp.Business/HRManagementApp.Business.csproj src/HRManagementApp.Business/
COPY src/HRManagementApp.DataAccess/HRManagementApp.DataAccess.csproj src/HRManagementApp.DataAccess/
RUN dotnet restore HRManagementApp.slnx

COPY src/ src/
RUN dotnet publish src/HRManagementApp/HRManagementApp.csproj \
    --configuration Release --no-restore --output /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "HRManagementApp.dll"]
