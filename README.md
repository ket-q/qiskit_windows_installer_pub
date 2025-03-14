<div align="center">
  <h1 align="center">Qiskit Installer for WIndows</h1>
</div>

<div align="center">

  <!-- PROJECT LOGO -->
  <br />
    
  <img alt="QiskitWindowslogo" src="ressources/assets/Logo.svg" width="700" height="300">
    
  <br />
</div>

##  📍 What is QIWI ?

QIWI is a QIskit Windows installer will set up Qiskit and a local copy of VSCode on your computer, with a ready-to-use Python virtual environment for Jupyter notebooks.

<br />

## ⚠️ Important notice before installing  

- Only install software on a computer that is not production-level or mission-critical to you. (This is a general truth that does not pertain only to this installer.)

- If the installation fails: Create a fresh user account ([tutorial video for it](https://www.youtube.com/watch?v=LpPZ1oBjsnM)) and log in under this account to install Qiskit. This will help insulate your Qiskit SDK from other software you may have installed on your computer. This is particularly important if your computer already has a complicated installation history of software frameworks.

<br />


## 💥 Installation

### 🏃 Running the script!   

---

- **Method 1:** (recommended if you're ok with downloading and executing an executable on your computer):

  - Download and execute the qiskit_installer.exe. ([Click here](https://github.com/ket-q/qiskit_windows_installer_pub/raw/refs/heads/main/qiskit_installer.exe))
  - A blue Windows box may appears because it consider our program as a threat, if so click on "More informations" and "Execute anyway".


---
  
- **Method 2:** (if you want visibility into what you will execute): Run script with powershell:

  **Step 1**: Download the script qiskit_installer.ps1 
  - [Click here](https://github.com/ket-q/qiskit_windows_installer_pub/blob/main/qiskit_installer.ps1)
  - Click on "Download raw file" next to the pen ✏️
  
  **Step 2**: Open a powershell console
  - Press the Windows key or open start menu
  - Type "PowerShell" in the search bar and open it.  

  **Step 3**: Navigate to the qiksit_installer.ps1 download file.\
*When opening a powershell you will be placed at the user root and you need to go to the Downloads folder (or any other folder where you downloaded the script)*
  
  ```powershell
  cd ~\Downloads
  ```
  **Step 4** Execute the following command 
  ```powershell
  Set-ExecutionPolicy Bypass -Scope Process -Force && .\qiskit_installer.ps1
  ```

---


### 🚶 Step-by-step guide through the installation process: 

#### Step 1️⃣: Accept the license agreements in the pop-up window

![GIF aceppting licenses](https://github.com/ket-q/qiskit_windows_installer_pub/blob/main/ressources/assets/accepting.gif)


#### Step 2️⃣: Wait for the downloading of the packages and the opening of VS Code

Visual studio code will automaticaly open with a Jupyter notebook to setup your Qiskit account

#### Step 3️⃣: Step 3: Follow the step-by-step guide to run Jupyter notebooks and get you started on the IBM Quantum Platform. 

This setup notebok includes:
- Selecting a Python interpreter for your Jupyter notebook
- Adding your IBM Quantum API token to your Qiskit installation 


*You can also download the [notebook](https://raw.githubusercontent.com/ket-q/qiskit_windows_installer_pub/refs/heads/main/notebooks/IBM_account_setup.ipynb) setup manually.*

#### Step 4️⃣ (Optional): We recommended to save this setup notebook in a folder where you keep your quantum computing projects

<br />


## ✏️ Usage 

### 🚩 You need to will to select the correct kernel/interpreter for every new file using Qiskit:  🚩 

---

### With any Jupyter Notebook:

![GIF select kernel](https://github.com/ket-q/qiskit_windows_installer_pub/blob/main/ressources/assets/select.gif)

1. Click "Select Kernel" on the top right
2. Click "Python Environnements"
3. Click "qiskit"

### With Non-Jupyter Notebook (Python or Python based):

1. Open the command palette (Ctrl + Shift + P)
2. Select "Python : select interpreter"
3. Select our qiskit environnement "Python 3.* (Qiskit 1.*)"

You can now run Qiskit on Windows.


## 🔌 Technical informations 


### Qiskit Windows installer

The installer itself does not stay resident in the system as it stay isolated sinde your %appdata% to prevent any conflict from happenning.



## ❓ FAQ / SUPPORT / TROUBLESHOOTING




## 📜 License

[License of this installer](https://github.com/ket-q/qiskit_windows_installer_pub/blob/main/LICENSE)

During the installation, you are required to accept mutilple licences:
- [Visual studio code](https://code.visualstudio.com/license)
- [Qiskit](https://github.com/Qiskit/qiskit/blob/main/LICENSE.txt)
- [Python](https://docs.python.org/3/license.html#terms-and-conditions-for-accessing-or-otherwise-using-python)
- [Pyenv-win](https://pyenv-win.github.io/pyenv-win/#license-and-copyright)


