# Stop the script when a cmdlet or a native command fails
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$python_version = "3.12.9"
$qiskit_version = "1.3.2"
$qwi_vstr = "qwi_p" + $python_version.Replace(".", "_") + "_q" + $qiskit_version.Replace(".", "_")

# # Elevating to Administrator rights..."

# # Get the ID and security principal of the current user account
# $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
# $myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);

# # Get the security principal for the administrator role
# $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;

# # Check to see if we are currently running as an administrator
# if ($myWindowsPrincipal.IsInRole($adminRole))
# {
#     # We are running as an administrator, so change the title and background colour to indicate this
#     $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)";
#     #$Host.UI.RawUI.BackgroundColor = "DarkBlue";
#     #Clear-Host;
#     Write-Host "Script running as administrator..."
# } else {
#     # We are not running as an administrator, so relaunch as administrator
#     Write-Host "Script not running as administrator..."

#     # Create a new process object that starts PowerShell
#     $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";

#     # Specify the current script path and name as a parameter with added scope and support for scripts with spaces in it's path
#     $newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + " -NoExit'"

#     # Indicate that the process should be elevated
#     $newProcess.Verb = "runas";

#     # Start the new process
#     [System.Diagnostics.Process]::Start($newProcess);

#     # Exit from the current, unelevated, process
#     Exit;
# }

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

function Fatal-Error {
    param(
        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The error message to write")]
        [string]$err_msg,

        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Exit code of the program")]
        [int]$err_val
    )
    $first = $true
    ForEach ($line in $($err_msg -split "\r?\n|\r")) {
        if ($first) {
            Write-Host "ERROR: $line"
            $first = $false
        } else {
            Write-Host "       $line"
        }
    }
    Exit $err_val
}

function Log-Err {
<#
.SYNOPSIS
Take a variable-length list of error variables and output them one by one. If
the firstArg=='fatal', then terminate the script if any of the error variables
is non-empty.

Parameters:
(1) firstArg: 'fatal' or 'warn', to determine whether to terminate if any error
    variable is non-empty
(2) secondArg: a string containing an overall description what theses errors
    are about.
(3) listArgs: one or more error variables
#>
    param(
        [Parameter(
            Mandatory=$True,
            Position = 0
        )]
        [ValidateSet('fatal', 'warn')]
        [string]
        $firstArg = 'fatal',

        [Parameter(
            Mandatory=$True,
            Position = 1
        )]
        [string]
        $secondArg,
     
        [Parameter(
            Mandatory=$True,
            ValueFromRemainingArguments=$true,
            Position = 2
        )]
        [AllowEmptyString()]
        [string[]]
        $listArgs
    )
    # $listArgs cannot be empty, thus at least one error variable must be present
    $have_error = $false
    $err_count = 0
    $var_count = $listArgs.Length
    foreach ($listArg in $listArgs) {
        if ($listArg) {
            $have_error = $true
            $err_count = $err_count + 1
        }
    }
    
    # If all error variables are empty (no error occurred), we only log
    # and return.
    if (!$have_error) {
        $msg = "|STATUS| ${secondArg}: DONE"
        Write-Host $msg
        return
    }

    # Falling through here means at least one error variable was non-empty,
    # and we log the details.
    $sep = "-"*79
    Write-Host $sep
    $kind = $(If ($firstArg -eq 'fatal') {"ERROR"} Else {"WARNING"})
    $ending = $(If ($var_count -gt 1) {"s"} Else {""})
    Write-Host "${kind}${ending} from '${secondArg}':"
    #'$firstArg: {0}' -f $firstArg
    $count = 0
    foreach ($listArg in $listArgs) {
        Write-Host $sep
        'Var[{0}]: {1}' -f $count, $(If ($listArg) {$listArg} Else {"OK"})
        $count++
    }
    Write-Host $sep

    if (($firstArg -eq 'fatal') -and $have_error) {
        # Terminate the script
        Exit 1
    }
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
        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Name of VSCode extension to install")]
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
# [void] (Get-ChildItem -Path "C:\Users" -ErrorAction SilentlyContinue -ErrorVariable err_1)
# [void] (Get-ChildItem -Path "C:\foo" -ErrorAction SilentlyContinue -ErrorVariable err_2)
# Log-Err 'fatal' 'The paths I tried' $err_1 $err_2
# Write-Host 'got past'
# Exit 0
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
if ( !(Get-Command pyenv -ErrorAction SilentlyContinue) ) {
    Write-Host("pyenv-win not installed, running installer")
    Install-pyenv-win
    Refresh-PATH
    Refresh-pyenv_Env
    # Ensure pyenv-win installation succeeded:
    if ( !(Get-Command pyenv -ErrorAction SilentlyContinue) ) {
        $err_msg = (
            "pyenv-win installation failed.",
            "Manual check required."
            ) -join "`r`n"
        Fatal-Error $err_msg 1
    } else {
        Write-Host("pyenv-win installation succeeded")
    }
} else {
    Write-Host("pyenv-win already installed")
}

#
# Python
#
Write-Header "Step 3: Install Python $python_version"
Write-Host "$env:LOCALAPPDATA"
Write-Host "You are in ${env:USERPROFILE}"
$QINST_ROOT = "${env:LOCALAPPDATA}\qiskit_windows_installer"
if (!(Test-Path $QINST_ROOT)){
    New-Item -Path "$QINST_ROOT" -ItemType Directory
}

$qinst_root_obj = get-item "$QINST_ROOT"

# Check that $QINST_ROOT is a folder and not a file. Required if
# the name already pre-existed in the filesystem.
if ( !($qinst_root_obj.PSIsContainer) ) {
    $err_msg = (
        "$QINST_ROOT is not a folder.",
        "Please move $QINST_ROOT out of the way and re-run the script."
        ) -join "`r`n"
    Fatal-Error $err_msg 1
} 

# Create $QINST_ROOT\$qwi_vstr, which is the enclave folder where we set up the
# virtual environment.
try {
    $QINST_ENCLAVE = Join-Path $QINST_ROOT -ChildPath $qwi_vstr
    if (!(Test-Path $QINST_ENCLAVE)){
         New-Item -Path "$QINST_ENCLAVE" -ItemType Directory
    }
    Set-Location -Path "$QINST_ENCLAVE"
}
catch {
    $err_msg = (
        "Unable to cd into $QINST_ENCLAVE.",
        "Manual intervention required."
        ) -join "`r`n"
    Fatal-Error $err_msg 1  
}

#
# We arrived in the enclave. Now
# (1) Check that the Python version asked by the user exists in  pyenv
# (2) setup the Python version asked by the user in the enclave folder
# (3) create the bootstrap venv that contains pipenv etc.
# (4) Use pipenv to create the ``official'' venv visible to the user in VSCode
#
$versions = Invoke-Command { pyenv install -l } `
     -ErrorAction SilentlyContinue `
     -ErrorVariable err_py_list
# For the regexp match, the dots in the version string are meta-chars:
$version_pattern = [regex]::Escape($python_version)
# \b means we only match on word boundaries.
if (!$versions -match "\b${version_pattern}\b") {
    $err_py_ver = "pyenv does not provide Python version '$python_version'"
}
Invoke-Command { pyenv install $python_version } `
    -ErrorAction SilentlyContinue `
    -ErrorVariable err_py_inst
Invoke-Command { pyenv local $python_version } `
    -ErrorAction SilentlyContinue `
    -ErrorVariable err_py_setlocal
Log-Err 'fatal' 'pyenv Python setup in enclave' $err_py_list $err_py_ver $err_py_inst $err_py_setlocal

$boot_venv_name = "venv_boot"

# Delete a pre-existing bootstrap venv
try {
    if (Test-Path $boot_venv_name) {
        # The bootstrap venv seems to exist already -> remove
        rm -R .\$boot_venv_name
    }
}
catch {
    $err_msg = (
        "Unable to remove existing bootstrap venv in enclave.",
        "Path: $QINST_ENCLAVE",
        "Name of venv: '$boot_venv_name'"
        ) -join "`r`n"
    Fatal-Error $err_msg 1
}

# Create bootstrap venv
Invoke-Command { pyenv exec python -m venv $boot_venv_name } `
     -ErrorAction SilentlyContinue `
     -ErrorVariable err_boot_venv
# Activate bootstrap venv
Invoke-Command { ".\${boot_venv_name}\Scripts\activate" } `
    -ErrorAction SilentlyContinue `
    -ErrorVariable err_boot_venv_activate
# Update pip of bootstrap venv
Invoke-Command { pyenv exec python -m pip install --upgrade pip } `
    -ErrorAction SilentlyContinue `
    -ErrorVariable err_boot_pip_upgr
# Install pipenv in venv
Invoke-Command { pyenv exec pip install pipenv } `
    -ErrorAction SilentlyContinue `
    -ErrorVariable err_boot_pipenv
Log-Err 'fatal' 'bootstrap venv setup in enclave' `
    $err_boot_venv $err_boot_venv_activate $err_boot_pip_upgr $err_boot_pipenv

# Create 'official' venv

# w/o pipenv (rationale: pipenv is extremely slow in installing packages):
# pyenv exec python -m venv C:\Users\bburg\.virtualenvs\my_test
# cd C:\Users\bburg\.virtualenvs\
# .\my_test\Scripts\activate
# (my_test) PS C:\Users\bburg> python -m pip install --upgrade pip
# pip install ipykernel
# pip install -r requirements.txt
# python -m ipykernel install --user --name=my_qiskit --display-name "my_qiskit"  # restart VSCode for Jupyter kernel to become visible


# old:
#pyenv exec pipenv install -r requirements.txt
#pyenv exec pipenv install
#pyenv exec pipenv install ipykernel
