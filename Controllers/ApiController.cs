using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace AzureWebApp.Controllers
{
    [ApiController]
    [Route("api/v1")]
    public class ApiController : ControllerBase
    {
        private readonly ILogger<ApiController> _logger;

        public ApiController(ILogger<ApiController> logger)
        {
            _logger = logger;
        }

        [HttpGet("hello")]
        public IActionResult Hello()
        {
            _logger.LogInformation("Hello endpoint processed a GET request");
            return Ok("Welcome to Azure App Service!");
        }

        [HttpPost("hello")]
        public IActionResult HelloPost()
        {
            _logger.LogInformation("Hello endpoint processed a POST request");
            return Ok("Welcome to Azure App Service!");
        }

        [HttpGet("error")]
        public IActionResult Error()
        {
            _logger.LogError("Error endpoint called - about to throw exception for testing purposes");
            throw new InvalidOperationException("This is a test exception for Application Insights telemetry");
        }

        [HttpGet("random")]
        public IActionResult Random()
        {
            var random = new Random();
            var randomValue = random.Next(1, 101); // 1 to 100 inclusive

            _logger.LogInformation("Random endpoint generated value: {RandomValue}", randomValue);
            return Ok(randomValue.ToString());
        }
    }
} 