FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY Directory.Packages.props ./
COPY global.json ./
COPY src/SomineApi.Domain/SomineApi.Domain.csproj src/SomineApi.Domain/
COPY src/SomineApi.Application/SomineApi.Application.csproj src/SomineApi.Application/
COPY src/SomineApi.Infrastructure/SomineApi.Infrastructure.csproj src/SomineApi.Infrastructure/
COPY src/SomineApi.WebApi/SomineApi.WebApi.csproj src/SomineApi.WebApi/

RUN dotnet restore src/SomineApi.WebApi/SomineApi.WebApi.csproj

COPY src ./src

RUN dotnet publish src/SomineApi.WebApi/SomineApi.WebApi.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080

COPY --from=build /app/publish ./

RUN apt-get update && apt-get install -y --no-install-recommends libgssapi-krb5-2 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/uploads

USER $APP_UID

ENTRYPOINT ["dotnet", "SomineApi.WebApi.dll"]
