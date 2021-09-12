FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim AS build-env
WORKDIR /app

COPY /src/WebApp/*.csproj ./src/WebApp/
COPY /test/WebApp.Tests/*.csproj ./src/WebApp.Tests/
RUN dotnet restore "./src/WebApp/WebApp.csproj" -s "https://api.nuget.org/v3/index.json"

COPY . ./
RUN dotnet test test/WebApp.Tests/*.csproj
RUN dotnet publish src/WebApp/*.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:5.0-buster-slim
WORKDIR /app
COPY --from=build-env /app/publish .
ENTRYPOINT ["dotnet", "WebApp.dll"]