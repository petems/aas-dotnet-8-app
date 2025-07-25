using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

public partial class Program
{
    public static void Main()
    {
        var host = new HostBuilder()
            .ConfigureFunctionsWorkerDefaults()
            .ConfigureLogging(logging =>
            {
                // Set minimum log level to Information
                logging.SetMinimumLevel(LogLevel.Information);
                
                // Add Application Insights if connection string is available
                var connectionString = Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING");
                if (!string.IsNullOrEmpty(connectionString))
                {
                    logging.AddApplicationInsights(configureTelemetryConfiguration: (config) =>
                        config.ConnectionString = connectionString, configureApplicationInsightsLoggerOptions: (options) => { });
                }
            })
            .Build();

        host.Run();
    }
}