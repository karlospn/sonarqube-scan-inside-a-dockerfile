#############
## Stage 1 ##
#############
FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim AS build-env
WORKDIR /app

## Install Java, because the sonarscanner needs it.
##RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y openjdk-11-jre

## RUN apt-get update && apt-get install -y openjdk-11-jdk

## Install sonarscanner
## RUN dotnet tool install --global dotnet-sonarscanner --version 5.3.1

## Install report generator
## RUN dotnet tool install --global dotnet-reportgenerator-globaltool --version 4.8.12

## Set the dotnet tools folder in the PATH env variable
## ENV PATH="${PATH}:/root/.dotnet/tools"
## Copy the applications .csproj
COPY /src/WebApp/*.csproj ./src/WebApp/

## Restore packages
RUN dotnet restore "./src/WebApp/WebApp.csproj" -s "https://api.nuget.org/v3/index.json"

## Copy everything else
COPY . ./

## Build the app
RUN dotnet build "./src/WebApp/WebApp.csproj" -c Release --no-restore
ARG sonarscan=no
## Start scanner
RUN if [ "$sonarscan" = "yes" ] ; then \
      apt-get update && apt-get install -y openjdk-11-jdk \
     && dotnet tool install --global dotnet-sonarscanner --version 5.3.1 && dotnet tool install --global dotnet-reportgenerator-globaltool --version 4.8.12 \
     && export PATH="${PATH}:/root/.dotnet/tools" \
     &&  dotnet sonarscanner begin \ 
	/k:"testimplementation" \
	/d:sonar.host.url="http://3.109.121.132:9000/" \
	/d:sonar.coverageReportPaths="coverage/SonarQube.xml" \
      && dotnet test test/WebApp.Tests/*.csproj --collect:"XPlat Code Coverage" --results-directory ./coverage \
      && reportgenerator "-reports:./coverage/*/coverage.cobertura.xml" "-targetdir:coverage" "-reporttypes:SonarQube" \
      && curl --request POST  --url 'https://api.bitbucket.org/2.0/repositories/nagarjunareddy398/testprrepomb/pullrequests/1/comments' --header 'Content-Type: application/json' -u nagarjunareddy398:FFbQLkTgR5rXQqAwnFxG -d '{"content": { "raw": " sample comment" }}' \
      && dotnet sonarscanner end ; \
      fi

## Publish the app
RUN dotnet publish src/WebApp/*.csproj -c Release -o /app/publish --no-build --no-restore

#############
## Stage 2 ##
#############
FROM mcr.microsoft.com/dotnet/aspnet:5.0-buster-slim
WORKDIR /app
COPY --from=build-env /app/publish .
ENTRYPOINT ["dotnet", "WebApp.dll"]
