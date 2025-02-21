# Stop the script when a cmdlet or a native command fails
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$python_version = "3.12.9" # 3.13 not working because ray requires Python 3.12
$qiskit_version = "1.3.2"
# Name of venv in .virtualenvs
$qwi_vstr = "testqiskit_" + $qiskit_version.Replace(".", "_")
# Name and URL of the requirements.txt file to download from GitHub:
#$requirements_file = "latest_requirements.txt"
$requirements_file = "symeng_requirements.txt"
$req_URL = "https://raw.githubusercontent.com/ket-q/launchpad/refs/heads/main/config/${requirements_file}"

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
    Write-Host "${kind}${ending} from ${secondArg}:"
    $count = 0
    foreach ($listArg in $listArgs) {
        Write-Host $sep
        $err_str = $(If ($listArg) {$listArg} Else {"OK"})
        Write-Host $('Err[{0}]: {1}' -f $count, $err_str)
        $count++
    }
    Write-Host $sep

    if (($firstArg -eq 'fatal') -and $have_error) {
        # Terminate the script
        Exit 1
    }
}


function Log-Status {
    <#
    .SYNOPSIS
    Friendly, informative-character logging only (no error, no warnings).
    Take a variable-length list of status variables and output them one by one.
    
    Parameters:
    (1) statusVars: one or more status variables of type string to output

    #>
    param(     
        [Parameter(
            Mandatory=$True,
            ValueFromRemainingArguments=$true,
            Position = 0
        )]
        [AllowEmptyString()]
        [string[]]
        $statusVars
    )
    
    foreach ($statusVar in $statusVars) {
        Write-Host $statusVar
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

    Log-Status "Downloading $source_URL..."

    # Use 'curl.exe' which is the Curl version provided on Win 10 and Win 11.
    # (The command 'curl' internally maps to Invoke-WebRequest.)
    try {
        $err = & curl.exe --silent -o $target_name $source_URL
    }
    catch {
        $err_msg = (
            "File download from $source_URL failed.",
            "Manual check required."
            ) -join "`r`n"
        Log-Err 'fatal' 'file download attempt' $err_msg
    }

    Log-Status 'Download DONE'
}

function Install-VSCode {
    $VSCode_installer = 'vscode_installer.exe'
    $VSCode_installer_path = Join-Path ${env:TEMP} -ChildPath $VSCode_installer
    # Download the local installer by appending '-user' to the download URL:
    $VSCode_URL = 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user'

    # Download VSCode
    Log-Status 'Downloading VSCode'
    Download-File $VSCode_URL $VSCode_installer_path

    # Install VSCode
    Log-Status 'Installing VSCode'
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
            HelpMessage = 'Name of VSCode extension to install')]
        [string]$ext
    )
    if ( $(@(code --list-extensions | ? { $_ -match $ext }).Count -ge 1) ) {
        Log-Status "VSCode extension $ext already installed"
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

function Check-pyenv-List {
    param (
        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Python version to look for in pyenv local list")]
        [string]$ver
    )
    try {
        $versions = & pyenv install -l
    }
    catch {
        Log-Err 'fatal' 'pyenv install -l' $($_.Exception.Message)
    }
    # For the regexp match, the dots in the version string are meta-chars
    # that we need to escape:
    $version_pattern = [regex]::Escape($ver)
    # \b means we only match on word boundaries.
    if ( !($versions -match "\b${version_pattern}\b") ) {
        Write-Host "pyenv does not list Python version '$ver'"
        return $false
    }
    Write-Host "pyenv supports Python version $ver"
    return $true
}

function Lookup-pyenv-Cache {
<#
.SYNOPSIS
Consult the pyenv local list of supported Python versions whether $ver is provided.
If not, determine whether our local pyenv list should be updated and re-check
after the update.

We generally try to avoid updating the local pyenv list because it is slow.
The only time we ever consider updating is when the thought-after Python version
in $ver does not show up in our local list. At that point we consider updating
the cache, but only if the last check is older than 12h.

Parameters:
    $ver: the version of Python we're looking for.

Return value:
    $true: if $ver can be provided by pyenv
    $false: otherwise
#>
    param (
        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = "Python version to look for in pyenv local list")]
        [string]$ver,

        [Parameter(
            Mandatory = $true,
            Position = 2,
            HelpMessage = "Path to the installer root folder")]
        [string]$ROOT_DIR
    )

    if ( (Check-pyenv-List $ver) ) {
        # Python $ver is supported
        return $true
    }

    # If we fall through here, then pyenv's local list of supported Python
    # versions does not contain $ver.

    $stamp = Join-Path $ROOT_DIR -ChildPath 'stamp.txt' # timestamp file
    $format = "yyyy-MM-dd_HH:mm:ss"  # timestamp format

    $need_refesh = $false  # Will be set to $true if pyenv cache is outdated
    $now = Get-Date

    if (!(Test-Path $stamp)) {
        # $stamp file does not exist, we never refreshed the cache
        $need_refresh = $true
    } else {
        # $stamp exists, determine whether the last check is past long enough
        # to warrant re-checking.
        $found = switch -File $stamp -RegEx {
            '^\d\d\d\d-\d\d-\d\d_\d\d:\d\d:\d\d$' {
                $timestamp = $matches[0]
                $true
                break }
            }
        if ( !$found ) {
            # $stamp does not contain a valid timestamp -> error out
            $err_args = 'fatal',
                'reading out timestamp of last pyenv cache update',
                'The timestamp file is corrupted.',
                "Path: $stamp"
            Log-Err @err_args
        }
        # If we fall through here we have date/time of last check in $timestamp
        $last_checked = [datetime]::ParseExact($timestamp, $format, $null)    
        $hours_since_last_check = ($now - $last_checked).TotalHours
        if ($hours_since_last_check -gt 12) {
            $need_refresh = $true
        }
    }

    if ( !$need_refresh ) {
        # A cache update was not necessary. Thus
        # there's no point in another lookup and we give up.
        Write-Host "pywin cache already updated within the last 12 hours."
        Write-Host "No further update was attempted."
        return $false
    }

    # If we fall through here, the cache update and re-lookup is required
    Write-Host "Your pywin cache was not updated within the last 12 hours."
    Write-Host "Updating now, which may take some time..."
    try {
        $discard = & pyenv update
    }
    catch {
        Log-Err 'fatal' 'pyenv update' $($_.Exception.Message)
    }
    # Update $stamp with new timestamp
    $now.ToString($format) | Out-File -FilePath $stamp

    # Cache update succeeded, test one more time and return result
    return Check-pyenv-List $ver
}



#
# Main
#

Set-ExecutionPolicy Bypass -Scope Process -Force

#
# VSCode
#
Write-Header 'Step 1: Install VSCode'
if (!(Get-Command code -ErrorAction SilentlyContinue) ) {
    Log-Status 'VSCode not not installed, running installer'
    Install-VSCode
    Refresh-PATH
} else {
    Log-Status 'VSCode already installed'
}
Log-Status 'Installing VSCode Python extension'
Install-VSCode-Extension 'ms-python.python'

Log-Status 'Installing VSCode Jupyter extension'
Install-VSCode-Extension 'ms-toolsai.jupyter'

#
# pyenv-win
#
Write-Header 'Step 2: Install pyenv-win'
if ( !(Get-Command pyenv -ErrorAction SilentlyContinue) ) {
    Lot-Status 'pyenv-win not installed, running installer'
    Install-pyenv-win
    Refresh-PATH
    Refresh-pyenv_Env
    # Ensure pyenv-win installation succeeded:
    if ( !(Get-Command pyenv -ErrorAction SilentlyContinue) ) {
        $err_msg = (
            'pyenv-win installation failed.',
            'Manual check required.'
            ) -join "`r`n"
        Log-Err 'fatal' 'pyenv-win installation' $err_msg
    } else {
        Log-Status 'pyenv-win installation succeeded'
    }
} else {
    Log-Status 'pyenv-win already installed'
}

#
# Set up installer root dir and enclave folder
#
Write-Header 'Step 3: set up installer root folder'
$ROOT_DIR = Join-Path ${env:LOCALAPPDATA} -ChildPath 'qiskit_windows_installer'
if (!(Test-Path $ROOT_DIR)){
    New-Item -Path $ROOT_DIR -ItemType Directory
}

$qinst_root_obj = get-item $ROOT_DIR

# Check that $ROOT_DIR is a folder and not a file. Required if
# the name already pre-existed in the filesystem.
if ( !($qinst_root_obj.PSIsContainer) ) {
    $err_msg = (
        "$ROOT_DIR is not a folder.",
        "Please move $ROOT_DIR out of the way and re-run the script."
        ) -join "`r`n"
    Fatal-Error $err_msg 1
} 

# Create the enclave folder $ROOT_DIR\$qwi_vstr. This is from where we
# set up the virtual environment.
Write-Header 'Step 4: set up enclave folder'
try {
    $ENCLAVE_DIR = Join-Path $ROOT_DIR -ChildPath $qwi_vstr
    if (!(Test-Path $ENCLAVE_DIR)) {
         $err = New-Item -Path $ENCLAVE_DIR -ItemType Directory
    }
    $err = Set-Location -Path $ENCLAVE_DIR
}
catch {
    $err_msg = (
        "Unable to cd into $ENCLAVE_DIR.",
        "Manual intervention required."
        ) -join "`r`n"
    Fatal-Error $err_msg 1  
}

#
# We arrived in the enclave. Now
# (0) Make sure that pyenv supported Python list is up-to-date
# (1) Check that the Python version asked by the user exists in pyenv
# (2) Install the Python version asked by the user
# (3) create the bootstrap venv that contains pipenv etc.
# (4) Use pipenv to create the ``official'' venv visible to the user in VSCode
#

# Write-Header "Step 4a: Check if pyenv supports Python $python_version"
# if ( !(Lookup-pyenv-Cache $python_version $ROOT_DIR) ) {
#     $err_msg = (
#         "Requested Python version $python_version not available with pyenv.",
#         "Please check manually on Python.org if you believe that Python",
#         "version $python_version should be available."
#         ) -join "`r`n"
#     Log-Err 'fatal' "availability-check of Python $python_version" $err_msg    
# }

Write-Header "Step 5: Set up Python $python_version for venv"
try {
    #$err = & pyenv install $python_version
    $err = & pyenv local $python_version
}
catch {
    Log-Err 'fatal' 'pyenv Python setup in enclave' $($_.Exception.Message)   
}

# # Make sure that user's '.virtualenvs' folder exists or otherwise create it.
# $DOT_VENVS_DIR = Join-Path ${env:USERPROFILE} -ChildPath '.virtualenvs'
# if (!(Test-Path $DOT_VENVS_DIR)){
#     New-Item -Path $DOT_VENVS_DIR -ItemType Directory
# }

# $dot_venvs_dir_obj = get-item $DOT_VENVS_DIR

# # Check that '.virtualenvs' is a folder and not a file. Required if
# # the name already pre-existed in the filesystem.
# if ( !($dot_venvs_dir_obj.PSIsContainer) ) {
#     $err_msg = (
#         "$DOT_VENVS_DIR is not a folder.",
#         "Please move $DOT_VENVS_DIR out of the way and re-run the script."
#         ) -join "`r`n"
#     Log-Err 'fatal' '.virtualenvs check' $err_msg
# }

# Test whether a venv of name $qwi_vstr already exists and delete it.
# Note 1: VSCode etc. should not use the venv in that moment, but we don't
# actually check this.
# FIXME: If a Jupyter notebook is open, then the rm command on the venv
#        will fail.

$MY_VENV_DIR = Join-Path ${DOT_VENVS_DIR} -ChildPath $qwi_vstr

# try {
#     if (Test-Path $MY_VENV_DIR) {
#         # A venv of that name seems to exist already -> remove
#         #rm -R $MY_VENV_DIR
#         # Remove-Item -Force -Recurse -Path $MY_VENV_DIR
#         Get-ChildItem $MY_VENV_DIR -Recurse | Remove-Item -Force -Recurse
#     }
# }
# catch {
#     $err_1 = $($_.Exception.Message)
#     $err_0 = (
#         "Unable to remove existing venv.",
#         "Path/venv: $MY_VENV_DIR"
#         ) -join "`r`n"
#     Log-Err 'fatal' $err_0 $err_1
# }

# Create and enter enclave folder $ROOT_DIR\$qwi_vstr. This is from where we
# will set up the virtual environment in .virtualenvs
try {
    $ENCLAVE_DIR = Join-Path $ROOT_DIR -ChildPath $qwi_vstr
    if ( !(Test-Path $ENCLAVE_DIR) ) {
         New-Item -Path $ENCLAVE -ItemType Directory
    }
    Set-Location -Path $ENCLAVE_DIR
}
catch {
    $err_msg = (
        "Unable to cd into $ENCLAVE_DIR.",
        "Manual intervention required."
        ) -join "`r`n"
    Log-Err 'fatal' 'cd into enclave folder' $err_msg  
}

# Download the requirements.txt file for the new venv
Download-File $req_URL ${requirements_file}

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

# # Update pip of venv
# Write-Header "Step 7: update pip of venv $MY_VENV_DIR"
# try {
#     & python -m pip install --upgrade pip
# }
# catch {
#     Log-Err 'fatal' 'Update pip of venv $MY_VENV_DIR' $($_.Exception.Message)
# }

# # Install ipykernel module in venv
# Write-Header "Step 8: install ipykernel module in venv $MY_VENV_DIR"
# try {
#     & pip install ipykernel
# }
# catch {
#     $err = $($_.Exception.Message)
#     $err_args = 'fatal',
#         'ipykernel module installation in venv $MY_VENV_DIR',
#         $err
#     Log-Err @err_args
# }

# Install Qiskit in venv
Write-Header "Step 9: install Qiskit in venv $MY_VENV_DIR"
try {   
    & pip install -r $requirements_file
}
catch {
    $err = $($_.Exception.Message)
    $err_args = 'fatal',
        'Qiskit installation in venv $MY_VENV_DIR',
        $err
    Log-Err @err_args
}

# # Install Jupyter server in venv
# Write-Header "Step 10: install ipykernel kernel in venv $MY_VENV_DIR"
# try {
#     $args = "-m", "ipykernel", "install",
#         "--user",
#         "--name=$qwi_vstr",
#         "--display-name", "`"$qwi_vstr`""
#     & python $args
# }
# catch {
#     $err = $($_.Exception.Message)
#     $err_args = 'fatal',
#         'ipykernel installation in venv $MY_VENV_DIR',
#         $err
#     Log-Err @err_args
# }

# Done
Exit 0