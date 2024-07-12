#!/usr/bin/env bash

set -ex

build_dir="${SRC_DIR}"/build-release
pre_install_dir="${SRC_DIR}"/pre-install
test_release_dir="${SRC_DIR}"/test-release

mkdir -p "${build_dir}"
mkdir -p "${pre_install_dir}"
cd "${SRC_DIR}"/build-release
  # Downloads and install toolbox as a static lib, make sure to remove it
  cmake -S "${SRC_DIR}" -B . \
  -D CMAKE_INSTALL_PREFIX="${pre_install_dir}" \
  -D CMAKE_BUILD_TYPE=Release \
  -D bip3x_BUILD_SHARED_LIBS=ON \
  -D bip3x_BUILD_JNI_BINDINGS=ON \
  -D bip3x_BUILD_C_BINDINGS=ON \
  -D bip3x_USE_OPENSSL_RANDOM=ON \
  -D bip3x_BUILD_TESTS=ON \
  -G Ninja
  cmake --build . -- -j"${CPU_COUNT}"
  cmake --install .
cd "${SRC_DIR}"

# Post-install toolbox removal
find "${pre_install_dir}" -name '*toolbox*' -print0 | while IFS= read -r -d '' file; do
  rm -rf "${file}"
done

# Prepare test area
mkdir -p "${test_release_dir}"
cp -r "${build_dir}"/bin "${test_release_dir}"
cd "${pre_install_dir}"
  find . -name '*[Gg][Tt]est*' -print0 | while IFS= read -r -d '' file; do
    tar cf - "${file}" | (cd "${test_release_dir}" && tar xf -)
    rm -rf "${file}"
  done
cd "${SRC_DIR}"

# Add alternative cmkae files location (bip3x not found by find_package() CMake)
# mkdir -p "${pre_install_dir}"/lib/cmake/bip3x
# cp "${pre_install_dir}"/lib/cmake/bip3x-config.cmake "${pre_install_dir}"/lib/cmake/bip3x/bip3xConfig.cmake
# cp "${pre_install_dir}"/lib/cmake/bip3x-config-version.cmake "${pre_install_dir}"/lib/cmake/bip3x/bip3xConfigVersion.cmake
# cp "${pre_install_dir}"/lib/cmake/bip3x-targets.cmake "${pre_install_dir}"/lib/cmake/bip3x/bip3xTargets.cmake
# cp "${pre_install_dir}"/lib/cmake/bip3x-targets-release.cmake "${pre_install_dir}"/lib/cmake/bip3x/bip3xTargets-release.cmake

# Transfer pre-install to PREFIX
(cd "${pre_install_dir}" && tar cf - ./* | (cd "${PREFIX}" && tar xvf -))
