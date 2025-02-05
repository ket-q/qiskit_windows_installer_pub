Write-Host "Elevating to Administrator rights..."

Disable-UAC

choco install -y python
    
Enable-UAC