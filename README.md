# qiskit_windows_installer
Installer for Qiskit on Microsoft Windows platforms.
## Installation
Before you begin, please read the Legal section (TBD).

To proceed with the installation, please click on the following link, which will download the installation script on your local computer, and prompt you to run with Administrator privileges (which it requires to perform its tasks). Clicking `yes` in this diaglog will start the installation.

 

[Qiskit Windows Installer script](http://boxstarter.org/package/url?https://raw.githubusercontent.com/ket-q/qiskit_windows_installer/main/box_install.ps1)

**Note:** for this to work you need a browser with ClickOnce support, such as Microsoft Edge or Internet Explorer.

## Appendices
### Chocolatey
* Installation of Chocolatey as part of the overall install script ([link](https://haricodes.com/chocolatey-windows-setup)).
* Installation of Python ([link](https://python-docs.readthedocs.io/en/latest/starting/install3/win.html)).
### Windows
* Placement of app-specific data on the Windows OS ([link](https://gist.github.com/ryangoree/67c26bad170f299eec43622038b79512)).
### VS Code
* Manually specifying a Python interpreter ([link](https://code.visualstudio.com/docs/python/environments#_manually-specify-an-interpreter
)).
### Python
#### Python virtual environments
* Installation of the IPython kernel, which is the Python execution backend for Jupyter ([link](https://ipython.readthedocs.io/en/stable/install/kernel_install.html)).
### Powershell
* Self-elevation of Powershell script ([link](https://stackoverflow.com/questions/60209449/how-to-elevate-a-powershell-script-from-within-a-script)).
### Related projects
* windows-dev-box-setup-scripts ([link](https://github.com/Microsoft/windows-dev-box-setup-scripts?tab=readme-ov-file)).
* SO discussion ([link](https://stackoverflow.com/questions/48144104/powershell-script-to-install-chocolatey-and-a-list-of-packages)).