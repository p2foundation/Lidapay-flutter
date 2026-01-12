# Quick Fix Guide for Flutter Doctor Issues

## Current Issues Detected

1. ❌ Android cmdline-tools component is missing
2. ❌ Android license status unknown
3. ❌ Visual Studio not installed (only needed for Windows app development)

## Quick Fix Steps

### Step 1: Fix Android cmdline-tools (Required for Android Development)

**Method A: Using Android Studio (Easiest & Recommended) ⭐**

This is the most reliable method and handles everything automatically:

1. **Open Android Studio**
2. If no project is open, click **More Actions** → **SDK Manager**
   - OR if a project is open: **Tools** → **SDK Manager**
3. Click on the **SDK Tools** tab (at the top)
4. Scroll down and check ✅ **Android SDK Command-line Tools (latest)**
   - Make sure it shows a version number (e.g., "11.0")
5. Click **Apply** → **OK**
6. Wait for download and installation to complete (may take a few minutes)
7. Click **Finish** when done

**After installation, close and reopen your terminal/PowerShell**, then verify:
```powershell
# Check if sdkmanager is accessible
& "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --version
```

If this works, proceed to Step 2. If you get an error, try Method B below.

**Method B: Manual Installation (If Android Studio method doesn't work)**

1. **Download** command-line tools:
   - Visit: https://developer.android.com/studio#command-line-tools-only
   - Download "Command line tools only" for Windows
   - Save the zip file (e.g., to Downloads folder)

2. **Extract and install**:
   ```powershell
   # Create the directory
   New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest"
   
   # Extract the zip (replace with your download path)
   Expand-Archive -Path "$env:USERPROFILE\Downloads\commandlinetools-win-*.zip" -DestinationPath "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest" -Force
   
   # Note: The zip may contain a 'cmdline-tools' folder inside. If so, move contents up one level.
   ```

3. **Set environment variables** (if not already set):
   ```powershell
   # Set ANDROID_HOME
   [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', "$env:LOCALAPPDATA\Android\Sdk", 'User')
   
   # Add to PATH (get current PATH first)
   $currentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
   $sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
   $newPath = "$sdkPath\cmdline-tools\latest\bin;$sdkPath\platform-tools;$currentPath"
   [System.Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
   ```

4. **Close and reopen terminal**, then verify:
   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --version
   ```

### Step 2: Accept Android Licenses

After installing cmdline-tools, run:

```powershell
flutter doctor --android-licenses
```

Press `y` for each license prompt.

### Step 3: Visual Studio (Optional - Only for Windows App Development)

**Skip this if you only need Android/Web development.**

If you need Windows desktop app support:
1. Download Visual Studio Community (free): https://visualstudio.microsoft.com/downloads/
2. During installation, select **"Desktop development with C++"** workload
3. Include all default components
4. Restart terminal after installation

## Verify Fix

After completing the steps above, run:

```powershell
flutter doctor
```

You should see:
- ✅ Android toolchain - develop for Android devices
- ✅ Visual Studio - develop Windows apps (if installed)

## Environment Variables Check

Verify these are set correctly:

```powershell
# Check ANDROID_HOME
echo $env:ANDROID_HOME

# Should output something like: C:\Users\YourName\AppData\Local\Android\Sdk
```

If not set, add it:
```powershell
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', "$env:LOCALAPPDATA\Android\Sdk", 'User')
```

## Still Having Issues?

1. Restart your terminal/PowerShell after making changes
2. Run `flutter doctor -v` for detailed diagnostics
3. Check the full troubleshooting guide in `SETUP.md`

