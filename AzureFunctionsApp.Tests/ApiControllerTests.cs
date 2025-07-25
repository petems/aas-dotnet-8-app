using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Net;
using Xunit;
using AzureWebApp.Controllers;
using Microsoft.AspNetCore.Mvc;

namespace AzureWebApp.Tests
{
    public class ApiControllerTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly WebApplicationFactory<Program> _factory;
        private readonly HttpClient _client;

        public ApiControllerTests(WebApplicationFactory<Program> factory)
        {
            _factory = factory;
            _client = _factory.CreateClient();
        }

        [Fact]
        public async Task Hello_Get_ReturnsOkResult()
        {
            // Act
            var response = await _client.GetAsync("/api/v1/hello");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var content = await response.Content.ReadAsStringAsync();
            Assert.Equal("Welcome to Azure App Service!", content);
        }

        [Fact]
        public async Task Hello_Post_ReturnsOkResult()
        {
            // Act
            var response = await _client.PostAsync("/api/v1/hello", null);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var content = await response.Content.ReadAsStringAsync();
            Assert.Equal("Welcome to Azure App Service!", content);
        }

        [Fact]
        public async Task Random_Get_ReturnsOkResult()
        {
            // Act
            var response = await _client.GetAsync("/api/v1/random");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var content = await response.Content.ReadAsStringAsync();
            Assert.True(int.TryParse(content, out var randomValue));
            Assert.InRange(randomValue, 1, 100);
        }

        [Fact]
        public async Task Error_Get_ReturnsInternalServerError()
        {
            // Act
            var response = await _client.GetAsync("/api/v1/error");

            // Assert
            Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        }
    }

    public class ApiControllerUnitTests
    {
        [Fact]
        public void Hello_ReturnsOkResult()
        {
            // Arrange
            var logger = new TestLogger<ApiController>();
            var controller = new ApiController(logger);

            // Act
            var result = controller.Hello();

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(result);
            Assert.Equal("Welcome to Azure App Service!", okResult.Value);
        }

        [Fact]
        public void HelloPost_ReturnsOkResult()
        {
            // Arrange
            var logger = new TestLogger<ApiController>();
            var controller = new ApiController(logger);

            // Act
            var result = controller.HelloPost();

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(result);
            Assert.Equal("Welcome to Azure App Service!", okResult.Value);
        }

        [Fact]
        public void Random_ReturnsOkResultWithRandomValue()
        {
            // Arrange
            var logger = new TestLogger<ApiController>();
            var controller = new ApiController(logger);

            // Act
            var result = controller.Random();

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(result);
            var value = Assert.IsType<string>(okResult.Value);
            Assert.True(int.TryParse(value, out var randomValue));
            Assert.InRange(randomValue, 1, 100);
        }

        [Fact]
        public void Error_ThrowsInvalidOperationException()
        {
            // Arrange
            var logger = new TestLogger<ApiController>();
            var controller = new ApiController(logger);

            // Act & Assert
            Assert.Throws<InvalidOperationException>(() => controller.Error());
        }
    }

    public class TestLogger<T> : ILogger<T>
    {
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
        public bool IsEnabled(LogLevel logLevel) => true;
        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter) { }
    }
}