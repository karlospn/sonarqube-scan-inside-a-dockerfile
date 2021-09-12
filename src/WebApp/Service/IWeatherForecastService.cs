using System.Collections.Generic;

namespace WebApp.Service
{
    public interface IWeatherForecastService
    {
        IEnumerable<WeatherForecast> Get();
    }
}