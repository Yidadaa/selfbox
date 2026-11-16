$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
$output = "$taskRoot/.tools/mumu-long/ime"
$androidSdk = "$env:LOCALAPPDATA/Android/sdk"
$buildTools = "$androidSdk/build-tools/36.0.0"
$platform = "$androidSdk/platforms/android-37.0/android.jar"
$javaBin = 'C:/Program Files/Android/Android Studio/jbr/bin'
New-Item -ItemType Directory -Force "$output/classes", "$output/dex" | Out-Null
& "$buildTools/aapt.exe" package -f -M "$PSScriptRoot/AndroidManifest.xml" -S "$PSScriptRoot/res" -I $platform -F "$output/resources.apk"
if ($LASTEXITCODE) { throw 'Resource packaging failed' }
& "$javaBin/javac.exe" -encoding UTF-8 -source 8 -target 8 -bootclasspath $platform -d "$output/classes" "$PSScriptRoot/ProfileKeyboard.java"
if ($LASTEXITCODE) { throw 'Java compilation failed' }
& "$javaBin/jar.exe" cf "$output/classes.jar" -C "$output/classes" .
& "$buildTools/d8.bat" --lib $platform --output "$output/dex" "$output/classes.jar"
if ($LASTEXITCODE) { throw 'Dex compilation failed' }
Copy-Item "$output/resources.apk" "$output/unsigned.apk" -Force
& "$javaBin/jar.exe" uf "$output/unsigned.apk" -C "$output/dex" classes.dex
& "$buildTools/zipalign.exe" -f 4 "$output/unsigned.apk" "$output/aligned.apk"
& "$buildTools/apksigner.bat" sign --ks "$taskRoot/.tools/android-user/debug.keystore" --ks-pass pass:android --key-pass pass:android --out "$output/profile-ime.apk" "$output/aligned.apk"
if ($LASTEXITCODE) { throw 'APK signing failed' }
Write-Output "$output/profile-ime.apk"
