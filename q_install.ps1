# Stop the script when a cmdlet or a native command fails
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$python_version = "3.12.9" # 3.13 not working because ray requires Python 3.12
$qiskit_version = "1.3.2"
# Name of venv in .virtualenvs
$qwi_vstr = "qiskit_" + $qiskit_version.Replace(".", "_")
# Name of the requirements.txt file to download from GitHub:
$requirements_file = "latest_requirements.txt"

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

function Download-File {
    param(
        [Parameter(
            Mandatory=$True,
            Position = 0
        )]
        [string]
        $source_URL,

        [Parameter(
            Mandatory=$True,
            Position = 1
        )]
        [string]
        $target_name
    )

    Write-Host "Downloading $source_URL..."

    # Use 'curl.exe' which is the Curl version provided on Win 10 and Win 11.
    # (The command 'curl' internally maps to Invoke-WebRequest.)
    try {
        curl.exe -o $target_name $source_URL
    }
    catch {
        $err_msg = (
            "File download from $source_URL failed.",
            "Manual check required."
            ) -join "`r`n"
        Fatal-Error $err_msg 1
    }

    Write-Host "Download DONE"
}

function Install-VSCode {
    $VSCode_installer = "vscode_installer.exe"
    $VSCode_installer_path = Join-Path ${env:TEMP} -ChildPath $VSCode_installer
    # Download the local installer by appending '-user' to the download URL:
    $VSCode_URL = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"

    # Download VSCode
    Write-Host "Downloading VSCode"
    Download-File $VSCode_URL $VSCode_installer_path

    # Install VSCode
    Write-Host "Installing VSCode"
    $unattended_args = '/VERYSILENT /MERGETASKS=!runcode'
    Start-Process -FilePath $VSCode_installer_path -ArgumentList $unattended_args -Wait -Passthru

    # Cleanup
    Remove-Item $VSCode_installer_path
}

function Install-VSCode-Extension {
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

Set-ExecutionPolicy Bypass -Scope Process -Force

#
# VSCode
#
Write-Header "Step 1: Install VSCode"
if (!(Get-Command code -ErrorAction SilentlyContinue) ) {
    Write-Host("VSCode not not installed, running installer")
    Install-VSCode
    Refresh-PATH
} else {
    Write-Host("VSCode already installed")
}
Write-Host "Installing VSCode Python extension"
Install-VSCode-Extension "ms-python.python"

Write-Host "Installing VSCode Jupyter extension"
Install-VSCode-Extension "ms-toolsai.jupyter"

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

# Create the enclave folder $QINST_ROOT\$qwi_vstr. This is from where we
# set up the virtual environment.
Write-Header "Step 4: set up enclave folder"
try {
    $QINST_ENCLAVE = Join-Path $QINST_ROOT -ChildPath $qwi_vstr
    if (!(Test-Path $QINST_ENCLAVE)){
         $err = New-Item -Path "$QINST_ENCLAVE" -ItemType Directory
    }
    $err = Set-Location -Path "$QINST_ENCLAVE"
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
# (1) Check that the Python version asked by the user exists in pyenv
# (2) Install the Python version asked by the user
# (3) create the bootstrap venv that contains pipenv etc.
# (4) Use pipenv to create the ``official'' venv visible to the user in VSCode
#

Write-Header "Step 5: Set up Python $python_version for venv"
$versions = Invoke-Command { pyenv install -l } `
     -ErrorAction SilentlyContinue `
     -ErrorVariable err_py_list
# For the regexp match, the dots in the version string are meta-chars
# that we need to escape:
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

# Make sure that user's '.virtualenvs' folder exists or otherwise create it.
$DOT_VENVS_DIR = Join-Path ${env:USERPROFILE} -ChildPath '.virtualenvs'
if (!(Test-Path $DOT_VENVS_DIR)){
    New-Item -Path "$DOT_VENVS_DIR" -ItemType Directory
}

$dot_venvs_dir_obj = get-item "$DOT_VENVS_DIR"

# Check that '.virtualenvs' is a folder and not a file. Required if
# the name already pre-existed in the filesystem.
if ( !($dot_venvs_dir_obj.PSIsContainer) ) {
    $err_msg = (
        "$DOT_VENVS_DIR is not a folder.",
        "Please move $DOT_VENVS_DIR out of the way and re-run the script."
        ) -join "`r`n"
    Fatal-Error $err_msg 1
}

# Test whether a venv of name $qwi_vstr already exists and delete it.
# Note 1: VSCode etc. should not use the venv in that moment, but we don't
# actually check this.
# FIXME: If a Jupyter notebook is open, then the rm command on the venv
#        will fail.

$MY_VENV_DIR = Join-Path ${DOT_VENVS_DIR} -ChildPath $qwi_vstr

try {
    if (Test-Path $MY_VENV_DIR) {
        # A venv of that name seems to exist already -> remove
        #rm -R $MY_VENV_DIR
        # Remove-Item -Force -Recurse -Path $MY_VENV_DIR
        Get-ChildItem $MY_VENV_DIR -Recurse | Remove-Item -Force -Recurse
    }
}
catch {
    $err_1 = $($_.Exception.Message)
    $err_0 = (
        "Unable to remove existing venv.",
        "Path/venv: $MY_VENV_DIR"
        ) -join "`r`n"
    Log-Err 'fatal' $err_0 $err_1
}


$boot_venv_name = "venv_boot"


# Create and enter enclave folder $QINST_ROOT\$qwi_vstr. This is from where we
# set up the virtual environment in .virtualenvs.
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

# Download the requirements.txt file for the new venv
Download-File `
    "https://raw.githubusercontent.com/ket-q/launchpad/refs/heads/main/config/${requirements_file}" `
    "${requirements_file}"

# w/o pipenv (rationale: pipenv is extremely slow in installing packages):
# pyenv exec python -m venv C:\Users\bburg\.virtualenvs\my_test
# cd C:\Users\bburg\.virtualenvs\  # not needed
# .\my_test\Scripts\activate
# (my_test) PS C:\Users\bburg> python -m pip install --upgrade pip
# pip install ipykernel
# pip install -r requirements.txt
# python -m ipykernel install --user --name=my_qiskit --display-name "my_qiskit"  # restart VSCode for Jupyter kernel to become visible

# Create venv
Write-Header "Step 6: Set up venv $MY_VENV_DIR"
try {
    # create venv
    & pyenv exec python -m venv $MY_VENV_DIR
    # activate venv
    & "${MY_VENV_DIR}\Scripts\activate.ps1"
}
catch {
    Log-Err 'fatal' 'Setting up venv' $($_.Exception.Message) 1
}

#
# venv activated
# PATH now includes our venv
#

# Update pip of venv
Write-Header "Step 7: update pip of venv $MY_VENV_DIR"
try {
    & python -m pip install --upgrade pip
}
catch {
    Log-Err 'fatal' 'Update pip of venv $MY_VENV_DIR' $($_.Exception.Message) 1
}

# Install ipykernel module in venv
Write-Header "Step 8: install ipykernel module in venv $MY_VENV_DIR"
try {
    & pip install ipykernel
}
catch {
    $err = $($_.Exception.Message)
    $err_args = 'fatal',
        'ipykernel module installation in venv $MY_VENV_DIR',
        $err,
        1
    Log-Err @err_args
}

# Install Qiskit in venv
Write-Header "Step 9: install Qiskit in venv $MY_VENV_DIR"
try {   
    & pip install -r $requirements_file
}
catch {
    $err = $($_.Exception.Message)
    $err_args = 'fatal',
        'Qiskit installation in venv $MY_VENV_DIR',
        $err,
        1
    Log-Err @err_args
}

# Install Jupyter server in venv
Write-Header "Step 10: install ipykernel kernel in venv $MY_VENV_DIR"
try {
    $args = "-m", "ipykernel", "install",
        "--user",
        "--name=$qwi_vstr",
        "--display-name", "`"$qwi_vstr`""
    & python $args
}
catch {
    $err = $($_.Exception.Message)
    $err_args = 'fatal',
        'Qiskit installation in venv $MY_VENV_DIR',
        $err,
        1
    Log-Err @err_args
}

# Done
Exit 0