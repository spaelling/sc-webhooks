using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

using System.Runtime.InteropServices;

// SCSM //

// for Registry
using Microsoft.Win32;
// from Microsoft.EnterpriseManagement.Core.dll
using Microsoft.EnterpriseManagement;
using Microsoft.EnterpriseManagement.Common;
using Microsoft.EnterpriseManagement.Configuration;

// from Microsoft.EnterpriseManagement.UI.SdkDataAccess.dll
using Microsoft.EnterpriseManagement.UI.SdkDataAccess;
using Microsoft.EnterpriseManagement.UI.SdkDataAccess.DataAdapters;

// from Microsoft.EnterpriseManagement.UI.Foundation.dll
using Microsoft.EnterpriseManagement.UI.DataModel;
using Microsoft.EnterpriseManagement.ConsoleFramework;

namespace scwebhook
{
    public partial class Scwebhook : ServiceBase
    {
        protected EnterpriseManagementGroup enterpriseMngmtGrp;

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool SetServiceStatus(IntPtr handle, ref ServiceStatus serviceStatus);

        public enum ServiceState
        {
            SERVICE_STOPPED = 0x00000001,
            SERVICE_START_PENDING = 0x00000002,
            SERVICE_STOP_PENDING = 0x00000003,
            SERVICE_RUNNING = 0x00000004,
            SERVICE_CONTINUE_PENDING = 0x00000005,
            SERVICE_PAUSE_PENDING = 0x00000006,
            SERVICE_PAUSED = 0x00000007,
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct ServiceStatus
        {
            public long dwServiceType;
            public ServiceState dwCurrentState;
            public long dwControlsAccepted;
            public long dwWin32ExitCode;
            public long dwServiceSpecificExitCode;
            public long dwCheckPoint;
            public long dwWaitHint;
        };

        public Scwebhook()
        {
            InitializeComponent();
            eventLog1 = new System.Diagnostics.EventLog();
            
            if (!System.Diagnostics.EventLog.SourceExists(Constants.EVENT_LOG_SOURCE))
            {
                System.Diagnostics.EventLog.CreateEventSource(
                    Constants.EVENT_LOG_SOURCE, Constants.EVENT_LOG_NAME);
            }
            eventLog1.Source = Constants.EVENT_LOG_SOURCE;
            eventLog1.Log = Constants.EVENT_LOG_NAME;
        }

        protected override void OnStart(string[] args)
        {

            #if DEBUG
            System.Threading.Thread.Sleep(10000);
            #endif
            eventLog1.WriteEntry("In OnStart");

            // Update the service state to Start Pending.
            ServiceStatus serviceStatus = new ServiceStatus();
            serviceStatus.dwCurrentState = ServiceState.SERVICE_START_PENDING;
            serviceStatus.dwWaitHint = 100000;
            SetServiceStatus(this.ServiceHandle, ref serviceStatus);

            // Set up a timer to trigger every minute.
            System.Timers.Timer timer = new System.Timers.Timer();
            timer.Interval = 60000; // 60 seconds
            timer.Elapsed += new System.Timers.ElapsedEventHandler(this.OnTimer);
            timer.Start();

            //Get the server name to connect to
            String strServerName = "localhost";
                
                //Registry.GetValue(
                //"HKEY_CURRENT_USER\\Software\\Microsoft\\System Center\\2010\\Service Manager\\Console\\User Settings", 
                //"SDKServiceMachine", 
                //"localhost").ToString();

            try
            {
                //Connect to the server
                enterpriseMngmtGrp = new EnterpriseManagementGroup(strServerName);

                eventLog1.WriteEntry("Connected to SCSM SDK@" + strServerName);
            }
            catch (Exception e)
            {
                eventLog1.WriteEntry("Unable to connect to SCSM SDK@" + strServerName + "\nError was" + e.Message);
            }

            // FE3B3QW-D22-21730C819N
            // Update the service state to Running.
            serviceStatus.dwCurrentState = ServiceState.SERVICE_RUNNING;
            SetServiceStatus(this.ServiceHandle, ref serviceStatus);
        }

        protected override void OnStop()
        {
            eventLog1.WriteEntry("In onStop.");
        }

        protected override void OnContinue()
        {
            eventLog1.WriteEntry("In OnContinue.");
        }

        public void OnTimer(object sender, System.Timers.ElapsedEventArgs args)
        {
            int eventId = 42;
            // TODO: Insert monitoring activities here.
            eventLog1.WriteEntry("Monitoring the System", EventLogEntryType.Information, eventId);
        }
    }
}
