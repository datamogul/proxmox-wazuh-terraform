Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
# Entfernung aller AppX-Packages für alle User.

Get-AppxProvisionedPackage -Online | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
# Entfernung aller provisionierten Pakete.