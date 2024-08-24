# Define paths
$build_dir = Join-Path $env:SRC_DIR "build-release"
$test_release_dir = Join-Path $env:SRC_DIR "test-release"

# Update PATH
$env:PATH = "$env:PREFIX\bin;" + $env:PATH

# There's a TAB in CMakeLists.txt that fails conda patches mechanism
Invoke-Expression "patch -p0 --ignore-whitespace ${env:RECIPE_DIR}/patches/xxxx-find-toolbox-package.patch"

# Build and install
New-Item -Path $build_dir -ItemType Directory -Force

Set-Location $build_dir
    cmake $env:CMAKE_ARGS `
      -G "Ninja" `
      -D CMAKE_BUILD_TYPE=Release `
      -D CMAKE_INSTALL_PREFIX="$env:LIBRARY_PREFIX" `
      -D CMAKE_VERBOSE_MAKEFILE=ON `
      -D bip3x_BUILD_SHARED_LIBS=ON `
      -D bip3x_BUILD_JNI_BINDINGS=ON `
      -D bip3x_BUILD_C_BINDINGS=ON `
      -D bip3x_USE_OPENSSL_RANDOM=ON `
      -D bip3x_BUILD_TESTS=ON `
      $env:SRC_DIR
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    cmake --build . --config Release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    cmake --install . --config Release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location $env:SRC_DIR

# Remove 'toolbox' files
Get-ChildItem -Path $env:PREFIX -Recurse -Filter '*toolbox*' | Remove-Item -Force -Recurse

# Prepare test area
New-Item -Path $test_release_dir -ItemType Directory -Force | Out-Null
Copy-Item -Path (Join-Path $build_dir 'bin') -Destination $test_release_dir -Recurse
Get-ChildItem -Path $env:PREFIX -Recurse | Where-Object { $_.FullName -match 'GTest' -or $_.FullName -match 'gtest' } | ForEach-Object { Copy-Item -Path $_.FullName -Destination $test_release_dir -Recurse -Force }
Get-ChildItem -Path $env:PREFIX -Recurse | Where-Object { $_.FullName -match 'GTest' -or $_.FullName -match 'gtest' } | Remove-Item -Force -Recurse

# Test binary is not installed on windows, apparently
Get-ChildItem -Path (Join-Path $build_dir 'bip3x-test.exe') -Recurse | Where-Object { $_ -ne $null } | ForEach-Object { Copy-Item -Path $_.FullName -Destination (Join-Path $test_release_dir 'bin') -Recurse }

# CMake was patched to create versioned windows DLLs, but the side-effect is that it creates
# bip3x.3.lib as the primary library. let's also provide the .lib without the version number.
Get-ChildItem -Path $env:PREFIX -Recurse -Filter "*.lib" |
    Where-Object { $_.Name -match "-\d+\.lib$" } |
    ForEach-Object {
        $newName = $_.Name -replace "-\d+(\.lib)$", '$1'
        $newPath = Join-Path $_.Directory $newName
        Copy-Item -Path $_.FullName -Destination $newPath
    }

# CMake files installed in the wrong directory
New-Item -Path (Join-Path $env:PREFIX 'bip3x/cmake') -ItemType Directory -Force | Out-Null
Copy-Item -Path (Join-Path $env:PREFIX 'Library/lib/cmake/bip3x/*') -Destination (Join-Path $env:PREFIX 'bip3x/cmake') -Recurse

# Clean up
Remove-Item -Path $build_dir -Recurse -Force
