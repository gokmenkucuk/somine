FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY Directory.Packages.props ./
COPY global.json ./
COPY src/SomineWeb/SomineWeb.csproj src/SomineWeb/

RUN dotnet restore src/SomineWeb/SomineWeb.csproj

COPY src/SomineWeb ./src/SomineWeb

RUN dotnet publish src/SomineWeb/SomineWeb.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080

COPY --from=build /app/publish ./

USER $APP_UID

ENTRYPOINT ["dotnet", "SomineWeb.dll"]
