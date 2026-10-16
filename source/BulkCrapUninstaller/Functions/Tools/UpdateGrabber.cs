/*
    Copyright (c) 2017 Marcin Szeniak (https://github.com/Klocman/)
    Modified by Erick Bores, 2026 (Neverwas)
    Apache License Version 2.0
*/

using System;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Threading;
using BulkCrapUninstaller.Properties;
using Klocman.Forms;
using Klocman.Tools;

namespace BulkCrapUninstaller.Functions.Tools
{
    internal static class UpdateGrabber
    {
        /// <summary>
        ///     Look for updates while displaying a progress bar. At the end display a message box with the result.
        /// </summary>
        public static void LookForUpdates()
        {
            bool? result = null;
            Version latestVersion = null;
            var error = LoadingDialog.ShowDialog(null, Localisable.LoadingDialogTitleSearchingForUpdates,
                _ => { result = IsUpdateAvailable(Assembly.GetExecutingAssembly().GetName().Version, out latestVersion); });

            if (error == null)
            {
                switch (result)
                {
                    case null:
                        MessageBoxes.UpdateFailed("Unknown error");
                        break;

                    case true:
                        AskAndBeginUpdate(latestVersion);
                        break;

                    case false:
                        MessageBoxes.UpdateUptodate();
                        break;
                }
            }
            else
            {
                MessageBoxes.UpdateFailed(error.Message);
            }
        }

        public static void AskAndBeginUpdate(Version latestVersion)
        {
            if (MessageBoxes.UpdateAskToDownload(latestVersion))
            {
                try
                {
                    // Prevent log cleaner from running in portable builds
                    //EntryPoint.IsRestarting = true;

                    Process.Start(new ProcessStartInfo(LatestReleaseUrl) { UseShellExecute = true });
                }
                catch (Exception ex)
                {
                    EntryPoint.IsRestarting = false;

                    Console.WriteLine(ex);
                    MessageBoxes.UpdateFailed(ex.Message);
                }
            }
        }

        /// <summary>
        ///     Setup update system and automatically search for them if auto update is enabled.
        ///     Doesn't block, use delegates to interface.
        /// </summary>
        public static void Setup()
        {
            //UpdateSystem.UpdateFeedUri = Program.EnableDebug ? DebugUpdateFeedUri : UpdateFeedUri;
            //UpdateSystem.CurrentVersion = Assembly.GetExecutingAssembly().GetName().Version;
        }

        /// <summary>
        ///     Automatically search for updates if auto update is enabled.
        ///     Doesn't block, use delegates to interface.
        /// </summary>
        /// <param name="canDisplayMessage">updateFoundCallback will be called after this returns true</param>
        /// <param name="updateFoundCallback">Launched only if a new update was found. It's launched from a background thread.</param>
        public static void AutoUpdate(Func<bool> canDisplayMessage, Action<Version> updateFoundCallback)
        {
            if (Settings.Default.MiscCheckForUpdates && WindowsTools.IsNetworkAvailable())
            {
                new Thread(() =>
                {
                    if (IsUpdateAvailable(Assembly.GetExecutingAssembly().GetName().Version, out var updateVersion) == true)
                    {
                        while (!canDisplayMessage())
                            Thread.Sleep(100);

                        try
                        {
                            updateFoundCallback(updateVersion);
                        }
                        catch
                        {
                            // Ignore background error, not necessary
                        }
                    }
                })
                { Name = "UpdateCheck_Thread", IsBackground = true }.Start();
            }
        }

        public static string LatestReleaseUrl = "https://github.com/ErickuchoSan/Neverwas/releases/latest";

        public static Version CheckLatestVersion()
        {
            // Should result in something like "https://github.com/ErickuchoSan/Neverwas/releases/tag/v6.3.0.1"
            return ParseVersionFromReleaseUrl(GetFinalRedirect(LatestReleaseUrl));
        }

        /// <summary>
        /// Returns the version in a ".../releases/tag/v1.2.3.4" URL, or null when the URL has no version tag
        /// (for example when the repository has no releases yet and GitHub redirects to ".../releases").
        /// </summary>
        internal static Version ParseVersionFromReleaseUrl(string url)
        {
            if (string.IsNullOrWhiteSpace(url)) return null;
            const string marker = "/releases/tag/";
            var i = url.LastIndexOf(marker, StringComparison.OrdinalIgnoreCase);
            if (i < 0) return null;
            var tag = url.Substring(i + marker.Length).TrimStart('v', 'V');
            return Version.TryParse(tag, out var version) ? version : null;
        }

        /// <summary>
        /// Returns null if failed to look for updates, else returns if there is a newer version available
        /// </summary>
        public static bool? IsUpdateAvailable(Version currentVersion, out Version updateVersion)
        {
            updateVersion = null;
            try
            {
                var latestVersion = CheckLatestVersion();
                if (latestVersion == null)
                {
                    throw new WebException("Failed to get version from URL");
                }
                else if (latestVersion > currentVersion)
                {
                    updateVersion = latestVersion;
                    Console.WriteLine("A new version is available: " + latestVersion);
                    return true;
                }
                else
                {
                    Console.WriteLine("The current version is the latest");
                    return false;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("Failed to check for new versions: " + e.Message);
                return null;
            }
        }

        private static string GetFinalRedirect(string url)
        {
            if (string.IsNullOrWhiteSpace(url))
                return null;

            try
            {
                // https://stackoverflow.com/a/79339216
                using (var client = new HttpClient(new HttpClientHandler { AllowAutoRedirect = true }))
                {
                    client.Timeout = new TimeSpan(0, 0, 10);
                    using (var response = client.SendAsync(new HttpRequestMessage(HttpMethod.Head, url)))
                    {
                        var result = response.Result.RequestMessage?.RequestUri;
                        return result?.ToString();
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"GetFinalRedirect failed for url=[{url}] with exception: {ex}");
                return null;
            }
        }
    }
}