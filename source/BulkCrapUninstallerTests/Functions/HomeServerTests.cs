/*
    Copyright (c) 2026 Erick Bores
    Apache License Version 2.0
*/

using System;
using System.Net.Http;
using System.Threading.Tasks;
using BulkCrapUninstaller;
using BulkCrapUninstaller.Functions.Tools;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace BulkCrapUninstallerTests.Functions
{
    [TestClass]
    public class HomeServerTests
    {
        [TestMethod]
        public void ConnectionString_DoesNotPointToUpstreamServer()
        {
            Assert.IsFalse(Program.ConnectionString.Host.Contains("klocman", StringComparison.OrdinalIgnoreCase),
                "Home server must not be " + Program.ConnectionString);
        }

        [TestMethod]
        public async Task HomeServerClient_FailsWithoutNetwork()
        {
            using var client = Program.HomeServerClient;
            await Assert.ThrowsExactlyAsync<HttpRequestException>(
                () => client.PostAsync(new Uri("SendStats?userId=1&data=x", UriKind.Relative), null!));
        }

        [TestMethod]
        public async Task OfflineHttpHandler_FailsEveryRequest()
        {
            using var client = new HttpClient(new OfflineHttpHandler());
            await Assert.ThrowsExactlyAsync<HttpRequestException>(
                () => client.GetAsync(new Uri("https://example.com/")));
        }
    }
}
