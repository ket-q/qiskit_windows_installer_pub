# qiskit_windows_installer 
Installer for Qiskit on Microsoft Windows platforms.
## Installation
Before you begin, please read the Legal section (TBD).


**Download and execute our [Qiskit Windows Installer](https://github.com/ket-q/qiskit_windows_installer_pub/raw/refs/heads/main/qiskit_installer.exe)**


## Usage

### This insaller creates a private environnement with Qiskit to avoid any conflicts.

To use this properly, you need to select the correct interpreter when running your script. 

With VS Code:
1. Open the command palette (Ctrl + Shift + P)
2. Select "Python : select interpreter"
3. Select "Python 3.* (Qiskit 1.*)"

You can now run Qiskit on windows.

## Used tools 


### Pipenv
[Pipenv](https://pipenv.pypa.io/en/latest/) is a tool to manage Python virtual environments and their software packages, and to facilitate packaging of packages present in a virtual environment.
It is capable of `dependency resolution`, which makes sure that all package dependencies are met. An introductions to Pipenv is from RealPython ([link](https://realpython.com/pipenv-guide/)), more advanced usage is described on the Pipenv website ([link](https://docs.pipenv.org/advanced/#configuration-with-environment-variables)).
* A major advantage of Pipenv over the newer tool [Poetry](https://python-poetry.org/) is that Pipenv puts its venvs below the `~.virtualenvs` folder in the user's homedirectory, from where VSCode reliably picks it up. This is considerable benefit with novice users to be able to select their Python environment that hosts the Jupyter server. Poetry creates its environments in a different place. In principle, the Python plugin of VSCode claims to spot virtual environments created by Poetry ([link](https://code.visualstudio.com/docs/python/environments#_where-the-extension-looks-for-environments)), but in practice it only worked by setting the `python.venvPath` (at least on Windows 10).
#### Creating a venv that contains all necessary packages
Create a project directory, enter it, and create a virtual environment if one
does not already exist for that given directory (recall, all venvs are created
under `~.virtualenvs` and the path to the folder is encoded and added to the
venv name, e.g., )
```bash
mkdir pipenv-demo
cd pipenv-demo
pipenv shell --python 3.12
```
#### Further useful Pipenv commands
Purging a venv created by Pipenv. This will remove the venv under `~.virtualenvs`. You can then re-create it there (from the same folder), if you choose.
```bash
cd pipenv-demo
pipenv --rm
```

### Windows
* Placement of app-specific data on the Windows OS ([link](https://gist.github.com/ryangoree/67c26bad170f299eec43622038b79512)).
### VS Code
* Manually specifying a Python interpreter ([link](https://code.visualstudio.com/docs/python/environments#_manually-specify-an-interpreter
)).
### Python
#### Python virtual environments
* Installation of the IPython kernel, which is the Python execution backend for Jupyter ([link](https://ipython.readthedocs.io/en/stable/install/kernel_install.html)).
### Powershell
* `Invoke-Command` vs. call operator `&` ([link](https://stackoverflow.com/questions/68727495/start-process-invoke-command-or))
* `Invoke-Command` etc. command invocation and variable expansion ([link1](https://stackoverflow.com/questions/60979858/powershell-invoke-command-with-filepath-on-local-computer-vague-parameters-err/60980641#60980641), [link2](https://stackoverflow.com/questions/57677186/how-do-i-do-the-bash-equivalent-of-progpath-program-in-powershell/57678081#57678081])).
* Command invocation and script blocks ([MS link](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_script_blocks?view=powershell-7.5)).
#### Line continuation (avoiding the backtick `)
* Long-line continuation and splatting ([link](https://stackoverflow.com/questions/2608144/how-to-split-long-commands-over-multiple-lines-in-powershell)).
* Blog on line continuation ([link](https://get-powershellblog.blogspot.com/2017/07/bye-bye-backtick-natural-line.html)).
#### Other
* Self-elevation of Powershell script ([link](https://stackoverflow.com/questions/60209449/how-to-elevate-a-powershell-script-from-within-a-script)).
* Run Powershell script through Windows installer ([link](https://stackoverflow.com/questions/46221983/how-can-i-use-powershell-to-run-through-an-installer)).
### Related projects
* windows-dev-box-setup-scripts ([link](https://github.com/Microsoft/windows-dev-box-setup-scripts?tab=readme-ov-file)).
* SO discussion ([link](https://stackoverflow.com/questions/48144104/powershell-script-to-install-chocolatey-and-a-list-of-packages)).
### Poetry
* Step-by-step installation ([link](https://gist.github.com/Isfhan/b8b104c8095d8475eb377230300de9b0)).
* Official instructions ([link](https://python-poetry.org/docs/#installing-with-the-official-installer)).
