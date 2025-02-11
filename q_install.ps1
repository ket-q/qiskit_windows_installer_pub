# Stop the script when a cmdlet or a native command fails
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$python_version = "3.12.9"


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
    #$Host.UI.RawUI.BackgroundColor = "DarkBlue";
    #Clear-Host;
    Write-Host "Script running as administrator..."
} else {
    # We are not running as an administrator, so relaunch as administrator
    Write-Host "Script not running as administrator..."

    # Create a new process object that starts PowerShell
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";

    # Specify the current script path and name as a parameter with added scope and support for scripts with spaces in it's path
    $newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + " -NoExit'"

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

function Refresh-PATH {
    # Reload PATH environment variable to get modifications from program installers
    Write-Host "Refresh-Env old PATH: $env:path"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "Refresh-Env new PATH: $env:path"
}

function Refresh-pyenv_Env {
    # Reload PyEnv environment variable (except PATH) to get modifications from installer
    Write-Host "Refresh-Env old PYENV: $env:PYENV"
    $env:Path = [System.Environment]::GetEnvironmentVariable("PYENV","Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("PYENV","User")
    Write-Host "Refresh-Env new PYENV: $env:PYENV"

    Write-Host "Refresh-Env old PYENV_ROOT: $env:PYENV_ROOT"
    $env:Path = [System.Environment]::GetEnvironmentVariable("PYENV_ROOT","Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("PYENV_ROOT","User")
    Write-Host "Refresh-Env new PYENV_ROOT: $env:PYENV_ROOT"
    
    Write-Host "Refresh-Env old PYENV_HOME: $env:PYENV_HOME"
    $env:Path = [System.Environment]::GetEnvironmentVariable("PYENV_HOME","Machine") +
                ";" +
                [System.Environment]::GetEnvironmentVariable("PYENV_HOME","User")
    Write-Host "Refresh-Env new PYENV_HOME: $env:PYENV_HOME"    
}

function Install-VSC {
    param (
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "local or global install")]
        [ValidateSet('local','global')]
        [string[]]$Scope = 'global'
    )
    $Destination = "$env:TEMP\vscode_installer.exe"
    $VSCodeUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"

    # User vs. system-wide installation
    if ($Scope  -eq 'local') {
        $VSCodeUrl = $VSCodeUrl + '-user'
    }

    $UnattendedArgs = '/verysilent /mergetasks=!runcode'

    # Download VSCode
    Write-Host "Downloading VSCode"
    $ProgressPreference = 'SilentlyContinue' # omit progress update to favour fast download time
    Invoke-WebRequest -Uri $VSCodeUrl -OutFile $Destination

    # Install VSCode
    Write-Host "Installing VSCode"
    Start-Process -FilePath $Destination -ArgumentList $UnattendedArgs -Wait -Passthru

    # Cleanup
    Remove-Item $Destination
}

function Install-VSC-Extension {
    param (
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Extension to install")]
        [string]$ext
    )
    if ( $(@(code --list-extensions | ? { $_ -match "$ext" }).Count -ge 1) ) {
        Write-Host "VSCode extension $ext already installed"
    } else {
        code --install-extension $ext
    }
}

function Install-pyenv-win {
    # Download and install
    $ProgressPreference = 'SilentlyContinue' # omit progress update to favour fast download time
    Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
    
    # Cleanup
    Remove-Item install-pyenv-win.ps1
}

#
# Main
#

Set-ExecutionPolicy Bypass -Scope Process -Force

#
# VSCode
#
Write-Header "Step 1: Install VSCode"
if (!(Get-Command code -ErrorAction SilentlyContinue) ) {
    Write-Host("VSCode not not installed, running installer")
    Install-VSC local
    Refresh-PATH
} else {
    Write-Host("VSCode installed")
}
Write-Host "Installing VSCode Python extension"
Install-VSC-Extension "ms-python.python"

Write-Host "Installing VSCode Jupyter extension"
Install-VSC-Extension "ms-toolsai.jupyter"

#
# pyenv-win
#
Write-Header "Step 2: Install pyenv-win"
if (!(Get-Command pyenv -ErrorAction SilentlyContinue) ) {
    Write-Host("pyenv-win not not installed, running installer")
    Install-pyenv-win
    Refresh-PATH
    Refresh-pyenv_Env
} else {
    Write-Host("pyenv-win installed")
}

#
# Python
#
Write-Header "Step 3: Install Python $python_version"
Write-Host "$env:LOCALAPPDATA"
Write-Host "You are in ${env:USERPROFILE}"
$QINST_ROOT = "${env:LOCALAPPDATA}\qiskit_windows_installer"
New-Item -Path "$QINST_ROOT" -ItemType Directory

#if (!(Get-Command choco.exe -ErrorAction SilentlyContinue) ) {
#    Write-Host("not installed, running installer")
#    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
#    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#}




# Install Chocolatey
# powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"; if ($LASTEXITCODE -eq 0) { SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin" }

# Default ``yes'' for all questions to the user
# choco feature enable -n allowGlobalConfirmation

# choco install python