<#
.SYNOPSIS
    Flutter Android 빌드를 위한 헤드리스(Headless) Android 툴체인 설치 스크립트.
    (Android Studio 전체 설치 없이 JDK 17 + Android SDK cmdline-tools만 설치)

.DESCRIPTION
    이 스크립트는 다음을 수행합니다:
      1. scoop을 통해 Temurin JDK 17 설치 (실패 시 winget 폴백)
      2. JAVA_HOME 사용자 환경 변수 설정
      3. developer.android.com/studio 페이지에서 최신 cmdline-tools 버전 번호를 동적으로 탐색하여 다운로드
      4. %LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest 레이아웃으로 압축 해제
      5. sdkmanager로 필수 SDK 패키지 설치:
           - platform-tools
           - platforms;android-35, platforms;android-36
           - build-tools;35.0.0, build-tools;36.0.0
      6. 모든 SDK 라이선스 자동 동의 (echo y 반복 파이프)
      7. ANDROID_HOME 사용자 환경 변수 설정 (setx)
      8. flutter config --android-sdk 로 현재 세션에서도 즉시 적용
      9. flutter doctor --android-licenses 로 Flutter 쪽 라이선스 승인도 재확인
     10. flutter doctor -v 로 최종 검증

    스크립트는 멱등성(idempotent)을 가지도록 작성되었습니다.
    이미 설치된 구성 요소는 감지 시 건너뜁니다. 여러 번 실행해도 안전합니다.

.NOTES
    - Android Studio는 설치하지 않습니다 (cmdline-tools만 사용).
    - 시스템(Machine) 레벨 환경변수는 건드리지 않고, 사용자(User) 레벨만 설정합니다.
    - PowerShell 5.1 기준으로 작성되었습니다 (Windows 11).
#>

[CmdletBinding()]
param(
    # Flutter SDK가 설치된 경로 (scoop 기준). 필요 시 변경 가능.
    [string]$FlutterBin = "C:\Users\$env:USERNAME\scoop\apps\flutter\current\bin\flutter.bat",

    # 설치할 SDK 패키지 목록
    [string[]]$SdkPackages = @(
        "platform-tools",
        "platforms;android-35",
        "platforms;android-36",
        "build-tools;35.0.0",
        "build-tools;36.0.0"
    )
)

# 참고: 이 스크립트는 scoop, sdkmanager, flutter 등 여러 외부 네이티브 도구를 호출한다.
# 이런 도구들은 진행 상황(progress)을 정상적으로 stderr에 출력하는 경우가 많아서
# $ErrorActionPreference = "Stop" 으로 두면 정상 동작인데도 종료 오류로 오인되어 스크립트가
# 중간에 멈춰버린다. 따라서 EAP는 기본값(Continue)으로 두고, 실패 판정이 꼭 필요한 지점은
# throw 문과 명시적 조건 검사(Test-Path 등)로 처리한다.
$ErrorActionPreference = "Continue"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==== $Message ====" -ForegroundColor Cyan
}

function Test-CommandExists {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# -----------------------------------------------------------------------------
# 1) JDK 17 설치 (scoop 우선, 실패 시 winget 폴백)
# -----------------------------------------------------------------------------
Write-Step "1) JDK 17 (Temurin) 설치 확인"

$jdkRoot = "C:\Users\$env:USERNAME\scoop\apps\temurin17-jdk\current"

if (Test-Path "$jdkRoot\bin\java.exe") {
    Write-Host "이미 설치됨: $jdkRoot (건너뜀)" -ForegroundColor Green
}
else {
    if (Test-CommandExists "scoop") {
        Write-Host "scoop으로 JDK 17 설치를 시도합니다..."
        try {
            # java 버킷이 없으면 추가 (이미 있으면 scoop이 알아서 스킵)
            scoop bucket add java *> $null
            scoop install temurin17-jdk
        }
        catch {
            Write-Warning "scoop 설치 실패: $($_.Exception.Message)"
            Write-Warning "winget 폴백을 시도합니다."
        }
    }

    if (-not (Test-Path "$jdkRoot\bin\java.exe")) {
        # scoop 경로에 안 보이면 winget으로 폴백 설치 (winget 설치 시 경로가 다르므로 별도 확인 필요)
        if (Test-CommandExists "winget") {
            Write-Host "winget으로 Eclipse Temurin 17 JDK 설치를 시도합니다..."
            winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-source-agreements --accept-package-agreements
            Write-Warning "winget 설치본 사용 시 -JdkRoot 파라미터로 실제 설치 경로를 지정해 주세요."
        }
        else {
            throw "scoop과 winget 모두 사용할 수 없습니다. JDK 17을 수동으로 설치해 주세요."
        }
    }
}

if (-not (Test-Path "$jdkRoot\bin\java.exe")) {
    throw "JDK 설치 확인 실패: $jdkRoot\bin\java.exe 를 찾을 수 없습니다."
}

# JAVA_HOME 사용자 환경 변수 설정 (기존 값과 동일하면 재설정 스킵)
$currentJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
if ($currentJavaHome -ne $jdkRoot) {
    Write-Host "JAVA_HOME 사용자 환경변수 설정: $jdkRoot"
    setx JAVA_HOME "$jdkRoot" | Out-Null
}
else {
    Write-Host "JAVA_HOME 이미 올바르게 설정됨: $jdkRoot" -ForegroundColor Green
}
$env:JAVA_HOME = $jdkRoot

Write-Host "Java 버전 확인:"
& "$env:JAVA_HOME\bin\java.exe" -version 2>&1 | ForEach-Object { Write-Host "  $_" }

# -----------------------------------------------------------------------------
# 2) Android SDK cmdline-tools 설치 (Android Studio 없이)
# -----------------------------------------------------------------------------
Write-Step "2) Android SDK cmdline-tools 설치 확인"

$sdkRoot = "$env:LOCALAPPDATA\Android\Sdk"
$cmdlineToolsLatest = "$sdkRoot\cmdline-tools\latest"
$sdkManagerBat = "$cmdlineToolsLatest\bin\sdkmanager.bat"

New-Item -ItemType Directory -Path $sdkRoot -Force | Out-Null

if (Test-Path $sdkManagerBat) {
    Write-Host "이미 설치됨: $sdkManagerBat (건너뜀)" -ForegroundColor Green
}
else {
    Write-Host "developer.android.com/studio 페이지에서 최신 cmdline-tools 버전을 탐색합니다..."

    # 버전 번호는 릴리스마다 바뀌므로 페이지 내용에서 정규식으로 동적으로 추출한다.
    # 예: commandlinetools-win-14742923_latest.zip
    $studioPageUrl = "https://developer.android.com/studio"
    $zipFileName = $null

    try {
        $pageContent = (Invoke-WebRequest -Uri $studioPageUrl -UseBasicParsing -TimeoutSec 30).Content
        if ($pageContent -match "commandlinetools-win-(\d+)_latest\.zip") {
            $zipFileName = $matches[0]
            Write-Host "탐색된 파일명: $zipFileName" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "developer.android.com 페이지 fetch 실패: $($_.Exception.Message)"
    }

    if (-not $zipFileName) {
        throw "cmdline-tools 버전 번호를 자동으로 찾지 못했습니다. https://developer.android.com/studio#command-line-tools-only 에서 수동으로 확인 후 -ZipFileName 파라미터로 지정해 주세요."
    }

    $downloadUrl = "https://dl.google.com/android/repository/$zipFileName"
    $tmpZip = "$env:TEMP\commandlinetools-win.zip"

    Write-Host "다운로드 중: $downloadUrl"
    Write-Host "(약 150MB, BITS 전송 사용 - 재개 가능)"

    Remove-Item $tmpZip -ErrorAction SilentlyContinue
    Import-Module BitsTransfer -ErrorAction SilentlyContinue
    Start-BitsTransfer -Source $downloadUrl -Destination $tmpZip -Description "Android cmdline-tools"

    Write-Host "압축 해제 중..."
    $extractTmp = "$env:TEMP\cmdline-tools-extract"
    Remove-Item $extractTmp -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path $tmpZip -DestinationPath $extractTmp -Force

    # 압축을 풀면 "cmdline-tools" 폴더가 나오는데, 이를 cmdline-tools\latest 로 이동해야
    # sdkmanager가 올바른 경로 규칙(cmdline-tools/latest/bin/...)을 인식한다.
    New-Item -ItemType Directory -Path "$sdkRoot\cmdline-tools" -Force | Out-Null
    if (Test-Path $cmdlineToolsLatest) { Remove-Item $cmdlineToolsLatest -Recurse -Force }
    Move-Item "$extractTmp\cmdline-tools" $cmdlineToolsLatest

    Remove-Item $tmpZip -ErrorAction SilentlyContinue
    Remove-Item $extractTmp -Recurse -Force -ErrorAction SilentlyContinue

    if (-not (Test-Path $sdkManagerBat)) {
        throw "cmdline-tools 설치 후에도 sdkmanager.bat을 찾을 수 없습니다: $sdkManagerBat"
    }
    Write-Host "cmdline-tools 설치 완료: $cmdlineToolsLatest" -ForegroundColor Green
}

$env:ANDROID_HOME = $sdkRoot

# -----------------------------------------------------------------------------
# 3) SDK 라이선스 전체 동의 (비대화형)
# -----------------------------------------------------------------------------
Write-Step "3) Android SDK 라이선스 동의"

$licensesDir = "$sdkRoot\licenses"
$expectedLicenseCount = 6  # android-sdk-license 등 주요 라이선스 파일 개수 (환경에 따라 다를 수 있음)
$existingLicenseCount = 0
if (Test-Path $licensesDir) {
    $existingLicenseCount = (Get-ChildItem $licensesDir -File -ErrorAction SilentlyContinue | Measure-Object).Count
}

if ($existingLicenseCount -ge $expectedLicenseCount) {
    Write-Host "라이선스 이미 동의됨 ($existingLicenseCount개 파일 존재, 건너뜀)" -ForegroundColor Green
}
else {
    Write-Host "라이선스에 자동 동의합니다 (y 30회 파이프)..."
    $yesInput = (1..30 | ForEach-Object { "y" }) -join "`n"
    $yesInput | & $sdkManagerBat --licenses
}

# -----------------------------------------------------------------------------
# 4) 필수 SDK 패키지 설치
# -----------------------------------------------------------------------------
Write-Step "4) SDK 패키지 설치: $($SdkPackages -join ', ')"

function Test-PackageInstalled {
    param([string]$PackageName)

    switch -Regex ($PackageName) {
        '^platform-tools$' {
            return Test-Path "$sdkRoot\platform-tools\adb.exe"
        }
        '^platforms;(android-\d+)$' {
            $ver = $matches[1]
            return Test-Path "$sdkRoot\platforms\$ver\android.jar"
        }
        '^build-tools;([\d\.]+)$' {
            $ver = $matches[1]
            return Test-Path "$sdkRoot\build-tools\$ver\aapt.exe"
        }
        default {
            return $false
        }
    }
}

# 이미 (완전하게) 설치된 패키지는 재설치를 생략하여 시간을 절약한다.
$packagesToInstall = @()
foreach ($pkg in $SdkPackages) {
    if (Test-PackageInstalled -PackageName $pkg) {
        Write-Host "이미 설치됨: $pkg (건너뜀)" -ForegroundColor Green
    }
    else {
        # 이전 실행이 중간에 실패해 손상된 폴더가 남아있을 수 있으므로 정리 후 재설치
        if ($pkg -match '^build-tools;([\d\.]+)$') {
            $ver = $matches[1]
            $dir = "$sdkRoot\build-tools\$ver"
            if (Test-Path $dir) {
                Write-Warning "손상되었을 수 있는 기존 폴더 삭제: $dir"
                Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        $packagesToInstall += $pkg
    }
}

if ($packagesToInstall.Count -gt 0) {
    Write-Host "설치할 패키지: $($packagesToInstall -join ', ')"
    & $sdkManagerBat @packagesToInstall
}
else {
    Write-Host "모든 SDK 패키지가 이미 설치되어 있습니다." -ForegroundColor Green
}

# -----------------------------------------------------------------------------
# 5) ANDROID_HOME 사용자 환경 변수 설정
# -----------------------------------------------------------------------------
Write-Step "5) ANDROID_HOME 환경변수 설정"

$currentAndroidHome = [Environment]::GetEnvironmentVariable("ANDROID_HOME", "User")
if ($currentAndroidHome -ne $sdkRoot) {
    Write-Host "ANDROID_HOME 사용자 환경변수 설정: $sdkRoot"
    setx ANDROID_HOME "$sdkRoot" | Out-Null
}
else {
    Write-Host "ANDROID_HOME 이미 올바르게 설정됨: $sdkRoot" -ForegroundColor Green
}
$env:ANDROID_HOME = $sdkRoot

# -----------------------------------------------------------------------------
# 6) Flutter에 SDK 경로 알려주기 + 라이선스 재확인 (현재 세션 즉시 반영)
# -----------------------------------------------------------------------------
Write-Step "6) Flutter 설정 (재시작 없이 현재 세션에 즉시 반영)"

if (-not (Test-Path $FlutterBin)) {
    Write-Warning "Flutter 실행 파일을 찾을 수 없습니다: $FlutterBin"
    Write-Warning "-FlutterBin 파라미터로 올바른 경로를 지정해 주세요. (scoop 기준: scoop\apps\flutter\current\bin\flutter.bat)"
}
else {
    & $FlutterBin config --android-sdk "$sdkRoot"

    Write-Host "Flutter 쪽 Android 라이선스 재확인 (자동 동의)..."
    $yesInput = (1..30 | ForEach-Object { "y" }) -join "`n"
    $yesInput | & $FlutterBin doctor --android-licenses

    # -----------------------------------------------------------------------
    # 7) 최종 검증
    # -----------------------------------------------------------------------
    Write-Step "7) flutter doctor -v (최종 검증)"
    & $FlutterBin doctor -v
}

Write-Host ""
Write-Host "==== 완료 ====" -ForegroundColor Cyan
Write-Host "참고: 새로 연 터미널부터 JAVA_HOME / ANDROID_HOME 사용자 환경변수가 자동으로 적용됩니다."
Write-Host "현재 세션에서는 이 스크립트가 이미 `$env:JAVA_HOME 및 `$env:ANDROID_HOME 을 설정했습니다."
