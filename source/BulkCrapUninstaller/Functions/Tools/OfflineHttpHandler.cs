/*
    Copyright (c) 2026 Erick Bores
    Apache License Version 2.0
*/

using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace BulkCrapUninstaller.Functions.Tools
{
    /// <summary>
    /// Fails every request without opening a connection. Neverwas does not report crashes,
    /// ratings or usage statistics to any server.
    /// </summary>
    public sealed class OfflineHttpHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            return Task.FromException<HttpResponseMessage>(
                new HttpRequestException("Neverwas does not contact third-party servers: " + request.RequestUri));
        }
    }
}
