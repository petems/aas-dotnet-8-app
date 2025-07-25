using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;

namespace AzureFunctionsApp
{
    public class HttpTriggerFunction
    {
        private readonly ILogger<HttpTriggerFunction> _logger;

        public HttpTriggerFunction(ILogger<HttpTriggerFunction> logger)
        {
            _logger = logger;
        }

        [Function("Hello")]
        public async Task<HttpResponseData> Hello(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "hello")] HttpRequestData req)
        {
            _logger.LogInformation("Hello function processed a {Method} request to {Url}", 
                req.Method, req.Url);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
            await response.WriteStringAsync("Welcome to Azure Functions Worker!");

            return response;
        }

        [Function("Error")]
        public HttpResponseData Error(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = "error")] HttpRequestData req)
        {
            _logger.LogError("Error function called - about to throw exception for testing purposes");
            throw new InvalidOperationException("This is a test exception for Application Insights telemetry");
        }

        [Function("Random")]
        public async Task<HttpResponseData> Random(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "random")] HttpRequestData req)
        {
            var random = new Random();
            var randomValue = random.Next(1, 101); // 1 to 100 inclusive

            _logger.LogInformation("Random function generated value: {RandomValue}", randomValue);

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
            await response.WriteStringAsync(randomValue.ToString());

            return response;
        }
    }
}