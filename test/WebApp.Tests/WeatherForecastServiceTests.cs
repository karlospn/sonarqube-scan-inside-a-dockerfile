using System;
using System.Linq;
using WebApp.Service;
using Xunit;

namespace WebApp.Tests
{
    public class WeatherForecastServiceTests
    {
        [Fact]
        public void IFGetMethodIsCalled_ThenReturnsListOfForecasts()
        {
            var service = new WeatherForecastService();
            var result = service.Get().ToList();
            
            Assert.NotNull(result);
            Assert.NotEmpty(result);
            Assert.Equal(5, result.Count());

        }
    }
}
