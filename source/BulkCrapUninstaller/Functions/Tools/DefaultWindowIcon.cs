/*
    Copyright (c) 2026 Erick Bores
    Apache License Version 2.0
*/

using System.Drawing;
using System.Reflection;
using System.Windows.Forms;

namespace BulkCrapUninstaller.Functions.Tools
{
    /// <summary>
    /// Makes the Neverwas logo the icon of every window that does not set its own, so new upstream
    /// windows get the brand without editing their designer files. WinForms keeps that default in a
    /// private static field of <see cref="Form"/>; call <see cref="Apply"/> before the first window
    /// is created.
    /// </summary>
    internal static class DefaultWindowIcon
    {
        // "defaultIcon" in .NET 8; later WinForms versions renamed it "s_defaultIcon".
        private static readonly string[] FieldNames = { "defaultIcon", "s_defaultIcon" };

        /// <returns>False if this WinForms version keeps the default icon somewhere else.</returns>
        public static bool Apply(Icon icon)
        {
            foreach (var name in FieldNames)
            {
                var field = typeof(Form).GetField(name, BindingFlags.NonPublic | BindingFlags.Static);
                if (field == null || field.FieldType != typeof(Icon)) continue;
                field.SetValue(null, icon);
                return true;
            }
            return false;
        }
    }
}
