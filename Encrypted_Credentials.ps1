# Specify the directory where the encrypted credentials will be stored
$directoryPath = .\Encrypted_Credentials
# Check if the directory exists, if not, create it
if (!(Test-Path -Path $directoryPath)) {
    New-Item -ItemType Directory -Path $directoryPath
    Write-Host "Directory $directoryPath created." -ForegroundColor Green
}
# Specify the path to the CSV file containing the list of OneView Global Dashboards
$GlobalDashboards = Import-Csv -Path .\GlobalDashboards_List.csv
# Read the CSV file
$OGDList = Import-Csv -Path $GlobalDashboards
# Loop through each OneView in the list
foreach ($oneView in $OGDList) {
    # Ask for the OneView login credentials
    $credentials = Get-Credential -Message "Please enter your login credentials for $oneView"
    # Encrypt the credentials and store them in a secure file
    $encryptedCredentials = $credentials | ConvertFrom-SecureString
    Set-Content -Path "$directoryPath\$oneView-credentials.txt" -Value $encryptedCredentials
}