#############
## Stage 1 ##
#############
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim AS build-env
WORKDIR /app

## Install Java, because the sonarscanner needs it.

RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y openjdk-11-jre

## Install sonarscanner
RUN dotnet tool install --global dotnet-sonarscanner --version 5.3.1

## Install report generator
RUN dotnet tool install --global dotnet-reportgenerator-globaltool --version 4.8.12

## Set the dotnet tools folder in the PATH env variable
ENV PATH="${PATH}:/root/.dotnet/tools"
ARG sonarscan=yes
## Start scanner
RUN if [ "$sonarscan" = yes ] ; then \
       dotnet sonarscanner begin \
	/k:"testimplementation \
	/d:sonar.host.url="http://3.109.121.132:9000/" \
	/d:sonar.login="b4254a0e97265d862b24b657ad70a784062719a3" \ 
	/d:sonar.coverageReportPaths="coverage/SonarQube.xml" \
      && dotnet test test/WebApp.Tests/*.csproj --collect:"XPlat Code Coverage" --results-directory ./coverage \
      && reportgenerator "-reports:./coverage/*/coverage.cobertura.xml" "-targetdir:coverage" "-reporttypes:SonarQube" \
      && dotnet sonarscanner end /d:sonar.login="b4254a0e97265d862b24b657ad70a784062719a3"; \
      fi
## Copy the applications .csproj
COPY /src/WebApp/*.csproj ./src/WebApp/

## Restore packages
RUN dotnet restore "./src/WebApp/WebApp.csproj" -s "https://api.nuget.org/v3/index.json"

## Copy everything else
COPY . ./

## Build the app
RUN dotnet build "./src/WebApp/WebApp.csproj" -c Release --no-restore

## Run dotnet test setting the output on the /coverage folder
## RUN dotnet test test/WebApp.Tests/*.csproj --collect:"XPlat Code Coverage" --results-directory ./coverage

## Create the code coverage file in sonarqube format using the cobertura file generated from the dotnet test command
## RUN reportgenerator "-reports:./coverage/*/coverage.cobertura.xml" "-targetdir:coverage" "-reporttypes:SonarQube"

## Publish the app
RUN dotnet publish src/WebApp/*.csproj -c Release -o /app/publish --no-build --no-restore

## Stop scanner
## RUN dotnet sonarscanner end /d:sonar.login="$SONAR_TOKEN"

#############
## Stage 2 ##
#############
FROM mcr.microsoft.com/dotnet/aspnet:5.0-buster-slim
WORKDIR /app
COPY --from=build-env /app/publish .
ENTRYPOINT ["dotnet", "WebApp.dll"]
