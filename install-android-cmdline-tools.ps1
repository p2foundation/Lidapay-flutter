# PowerShell script to install Android SDK Command-line Tools
# Run this script as Administrator if needed

Write-Host "Installing Android SDK Command-line Tools..." -ForegroundColor Cyan

$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
$cmdlineToolsPath = "$sdkPath\cmdline-tools"
$latestPath = "$cmdlineToolsPath\latest"

# Create directories if they don't exist
if (-not (Test-Path $sdkPath)) {
    Write-Host "Creating SDK directory: $sdkPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $sdkPath -Force | Out-Null
}

if (-not (Test-Path $cmdlineToolsPath)) {
    Write-Host "Creating cmdline-tools directory: $cmdlineToolsPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $cmdlineToolsPath -Force | Out-Null
}

# Check if already installed
if (Test-Path "$latestPath\bin\sdkmanager.bat") {
    Write-Host "Command-line tools already installed at: $latestPath" -ForegroundColor Green
    Write-Host "Verifying installation..." -ForegroundColor Cyan
    
    # Set environment variable for current session
    $env:ANDROID_HOME = $sdkPath
    $env:PATH = "$latestPath\bin;$env:PATH"
    
    # Test sdkmanager
    & "$latestPath\bin\sdkmanager.bat" --version
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Command-line tools are working!" -ForegroundColor Green
        Write-Host "`nNext step: Run 'flutter doctor --android-licenses'" -ForegroundColor Cyan
        exit 0
    }
}

# Download URL for latest command-line tools
$downloadUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$zipPath = "$env:TEMP\android-cmdline-tools.zip"

Write-Host "`nDownloading Android Command-line Tools..." -ForegroundColor Cyan
Write-Host "URL: $downloadUrl" -ForegroundColor Gray
Write-Host "This may take a few minutes..." -ForegroundColor Yellow

try {
    # Download the zip file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    
    Write-Host "Download complete!" -ForegroundColor Green
    Write-Host "Extracting to: $latestPath" -ForegroundColor Cyan
    
    # Create latest directory
    if (-not (Test-Path $latestPath)) {
        New-Item -ItemType Directory -Path $latestPath -Force | Out-Null
    }
    
    # Extract zip file
    Expand-Archive -Path $zipPath -DestinationPath $latestPath -Force
    
    # The zip contains a 'cmdline-tools' folder, we need to move contents up one level
    $extractedCmdlineTools = "$latestPath\cmdline-tools"
    if (Test-Path $extractedCmdlineTools) {
        Write-Host "Reorganizing directory structure..." -ForegroundColor Cyan
        Get-ChildItem "$extractedCmdlineTools" | Move-Item -Destination $latestPath -Force
        Remove-Item $extractedCmdlineTools -Force -ErrorAction SilentlyContinue
    }
    
    # Clean up zip file
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    
    Write-Host "`n✅ Installation complete!" -ForegroundColor Green
    
    # Set environment variables for current session
    $env:ANDROID_HOME = $sdkPath
    $env:PATH = "$latestPath\bin;$env:PATH"
    
    # Set permanent environment variable
    [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', $sdkPath, 'User')
    
    # Update PATH permanently
    $currentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    $newPathEntries = @(
        "$latestPath\bin",
        "$sdkPath\platform-tools"
    )
    
    foreach ($entry in $newPathEntries) {
        if ($currentPath -notlike "*$entry*") {
            $currentPath = "$entry;$currentPath"
        }
    }
    
    [System.Environment]::SetEnvironmentVariable('PATH', $currentPath, 'User')
    
    Write-Host "`nEnvironment variables updated:" -ForegroundColor Cyan
    Write-Host "  ANDROID_HOME = $sdkPath" -ForegroundColor Gray
    Write-Host "  Added to PATH: $latestPath\bin" -ForegroundColor Gray
    Write-Host "  Added to PATH: $sdkPath\platform-tools" -ForegroundColor Gray
    
    # Verify installation
    Write-Host "`nVerifying installation..." -ForegroundColor Cyan
    & "$latestPath\bin\sdkmanager.bat" --version
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Command-line tools installed successfully!" -ForegroundColor Green
        Write-Host "`n⚠️  IMPORTANT: Close and reopen your terminal/PowerShell for changes to take effect." -ForegroundColor Yellow
        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "  1. Close this terminal" -ForegroundColor White
        Write-Host "  2. Open a new terminal" -ForegroundColor White
        Write-Host "  3. Run: flutter doctor --android-licenses" -ForegroundColor White
    } else {
        Write-Host "`n❌ Installation completed but verification failed." -ForegroundColor Red
        Write-Host "Please check the installation manually." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "`n❌ Error during installation: $_" -ForegroundColor Red
    Write-Host "`nManual installation steps:" -ForegroundColor Yellow
    Write-Host "1. Download from: https://developer.android.com/studio#command-line-tools-only" -ForegroundColor White
    Write-Host "2. Extract to: $latestPath" -ForegroundColor White
    Write-Host "3. Set ANDROID_HOME = $sdkPath" -ForegroundColor White
    exit 1
}

