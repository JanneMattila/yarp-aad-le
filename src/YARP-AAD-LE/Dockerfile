# https://hub.docker.com/_/microsoft-dotnet-sdk
#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.
ARG ARCH

FROM mcr.microsoft.com/dotnet/aspnet:8.0.1-alpine3.18-$ARCH AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0.101-alpine3.18-$ARCH AS build
WORKDIR /src
COPY ["src/YARP-AAD-LE/YARP-AAD-LE.csproj", "src/YARP-AAD-LE/"]
RUN dotnet restore "src/YARP-AAD-LE/YARP-AAD-LE.csproj"
COPY . .
WORKDIR "/src/src/YARP-AAD-LE"
RUN dotnet build "YARP-AAD-LE.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "YARP-AAD-LE.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "YARP-AAD-LE.dll"]