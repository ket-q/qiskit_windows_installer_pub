Write-Host "Elevating to Administrator rights..."

Disable-UAC

choco install -y python --version=3.12
# requirement of 'ray' of ibm-serverless

# Refresh path
refreshenv

# Update pip
python -m pip install --upgrade pip

choco install -y pyenv-win
    
Enable-UAC