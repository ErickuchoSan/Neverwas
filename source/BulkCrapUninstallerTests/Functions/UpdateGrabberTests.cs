/*
    Copyright (c) 2026 Erick Bores
    Apache License Version 2.0
*/

using System;
using BulkCrapUninstaller.Functions.Tools;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace BulkCrapUninstallerTests.Functions
{
    [TestClass]
    public class UpdateGrabberTests
    {
        [TestMethod]
        public void LatestReleaseUrl_PointsToNeverwas()
        {
            Assert.AreEqual("https://github.com/ErickuchoSan/Neverwas/releases/latest", UpdateGrabber.LatestReleaseUrl);
        }

        [TestMethod]
        [DataRow("https://github.com/ErickuchoSan/Neverwas/releases/tag/v6.3.0.1", "6.3.0.1")]
        [DataRow("https://github.com/ErickuchoSan/Neverwas/releases/tag/6.4.0.2", "6.4.0.2")]
        public void ParseVersionFromReleaseUrl_ReadsTag(string url, string expected)
        {
            Assert.AreEqual(new Version(expected), UpdateGrabber.ParseVersionFromReleaseUrl(url));
        }

        [TestMethod]
        [DataRow("https://github.com/ErickuchoSan/Neverwas/releases")]
        [DataRow("https://github.com/ErickuchoSan/Neverwas/releases/latest")]
        [DataRow("https://github.com/ErickuchoSan/Neverwas/releases/tag/nightly")]
        [DataRow("")]
        public void ParseVersionFromReleaseUrl_ReturnsNullWhenNoVersionTag(string url)
        {
            Assert.IsNull(UpdateGrabber.ParseVersionFromReleaseUrl(url));
        }

        [TestMethod]
        public void ParseVersionFromReleaseUrl_ReturnsNullForNull()
        {
            Assert.IsNull(UpdateGrabber.ParseVersionFromReleaseUrl(null));
        }
    }
}
