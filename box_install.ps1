Write-Host "Elevating to Administrator rights..."

Disable-UAC

# choco install -y python
choco install -y pyenv-win
    
Enable-UAC