using System.Drawing;
using System.Windows.Forms;
using BulkCrapUninstaller.Functions.Tools;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace BulkCrapUninstallerTests
{
    [TestClass]
    public class DefaultWindowIconTests
    {
        // Fails when a WinForms update moves the default icon: windows without their own icon
        // would go back to the generic one.
        [TestMethod]
        public void Apply_GivesWindowsWithoutTheirOwnIconTheLogo()
        {
            using var logo = new Icon(SystemIcons.Shield, 32, 32);

            try
            {
                Assert.IsTrue(DefaultWindowIcon.Apply(logo));

                using var form = new Form();
                Assert.AreSame(logo, form.Icon);
            }
            finally
            {
                // Null makes WinForms load its own default again, for the other tests.
                DefaultWindowIcon.Apply(null);
            }
        }
    }
}
