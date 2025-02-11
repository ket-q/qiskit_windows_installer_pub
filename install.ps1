# Stop the script when a cmdlet or a native command fails
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

# Elevating to Administrator rights..."

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);

# Get the security principal for the administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;

# Check to see if we are currently running as an administrator
if ($myWindowsPrincipal.IsInRole($adminRole))
{
    # We are running as an administrator, so change the title and background colour to indicate this
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)";
    $Host.UI.RawUI.BackgroundColor = "DarkBlue";
    Clear-Host;
} else {
    # We are not running as an administrator, so relaunch as administrator

    # Create a new process object that starts PowerShell
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";

    # Specify the current script path and name as a parameter with added scope and support for scripts with spaces in it's path
    $newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"

    # Indicate that the process should be elevated
    $newProcess.Verb = "runas";

    # Start the new process
    [System.Diagnostics.Process]::Start($newProcess);

    # Exit from the current, unelevated, process
    Exit;
}

function Write-Header {
    param(
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The message to write")]
        [string]$msg
    )
    $fill = "="*$msg.Length
    Write-Host "====$fill===="
    Write-Host "==  $msg  =="
    Write-Host "====$fill===="
}

#
# Main
#

Set-ExecutionPolicy Bypass -Scope Process -Force

Write-Header "Step 1: Install Chocolatey"
if (!(Get-Command choco.exe -ErrorAction SilentlyContinue) ) {
    Write-Host("not installed, running installer")
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}




# Install Chocolatey
# powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"; if ($LASTEXITCODE -eq 0) { SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin" }

# Default ``yes'' for all questions to the user
# choco feature enable -n allowGlobalConfirmation

# choco install python