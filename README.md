# Running sonarqube scanner when building a container image

This repository contains a practical example about how to execute a sonarqube scan when building a container image.

Here's how the end result looks like:

```yaml
#############
## Stage 1 ##
#############
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim AS build-env
WORKDIR /app

## Arguments for setting the Sonarqube Token and the Project Key
ARG SONAR_TOKEN
ARG SONAR_PRJ_KEY

## Setting the Sonarqube Organization and Uri
ENV SONAR_ORG "karlospn"
ENV SONAR_HOST "https://sonarcloud.io"

## Install Java, because the sonarscanner needs it.
RUN mkdir /usr/share/man/man1/
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y openjdk-11-jre

## Install sonarscanner
RUN dotnet tool install --global dotnet-sonarscanner --version 5.3.1

## Install report generator
RUN dotnet tool install --global dotnet-reportgenerator-globaltool --version 4.8.12

## Set the dotnet tools folder in the PATH env variable
ENV PATH="${PATH}:/root/.dotnet/tools"

## Start scanner
RUN dotnet sonarscanner begin \
        /o:"$SONAR_ORG" \
        /k:"$SONAR_PRJ_KEY" \
        /d:sonar.host.url="$SONAR_HOST" \
        /d:sonar.login="$SONAR_TOKEN" \ 
        /d:sonar.coverageReportPaths="coverage/SonarQube.xml"

## Copy the applications .csproj
COPY /src/WebApp/*.csproj ./src/WebApp/

## Restore packages
RUN dotnet restore "./src/WebApp/WebApp.csproj" -s "https://api.nuget.org/v3/index.json"

## Copy everything else
COPY . ./

## Run dotnet test setting the output on the /coverage folder
RUN dotnet test test/WebApp.Tests/*.csproj --collect:"XPlat Code Coverage" --results-directory ./coverage

## Create the code coverage file in sonarqube format using the cobertura file generated from the dotnet test command
RUN reportgenerator "-reports:./coverage/*/coverage.cobertura.xml" "-targetdir:coverage" "-reporttypes:SonarQube"

## Publish the app
RUN dotnet publish src/WebApp/*.csproj -c Release -o /app/publish

## Stop scanner
RUN dotnet sonarscanner end /d:sonar.login="$SONAR_TOKEN"

#############
## Stage 2 ##
#############
FROM mcr.microsoft.com/dotnet/aspnet:5.0-buster-slim
WORKDIR /app
COPY --from=build-env /app/publish .
ENTRYPOINT ["dotnet", "WebApp.dll"]
```

