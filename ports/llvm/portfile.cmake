# LLVM documentation recommends always using static library linkage when
#   building with Microsoft toolchain; it's also the default on other platforms
set(VCPKG_LIBRARY_LINKAGE static)

if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore")
    message(FATAL_ERROR "llvm cannot currently be built for UWP")
endif()

include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/llvm-6.0.1.src)
vcpkg_download_distfile(ARCHIVE
    URLS "http://releases.llvm.org/6.0.1/llvm-6.0.1.src.tar.xz"
    FILENAME "llvm-6.0.1.src.tar.xz"
    SHA512 cbbb00eb99cfeb4aff623ee1a5ba075e7b5a76fc00c5f9f539ff28c108598f5708a0369d5bd92683def5a20c2fe60cab7827b42d628dbfcc79b57e0e91b84dd9
)
vcpkg_extract_source_archive(${ARCHIVE})

vcpkg_download_distfile(CLANG_ARCHIVE
    URLS "http://releases.llvm.org/6.0.1/cfe-6.0.1.src.tar.xz"
    FILENAME "cfe-6.0.1.src.tar.xz"
    SHA512 f64ba9290059f6e36fee41c8f32bf483609d31c291fcd2f77d41fecfdf3c8233a5e23b93a1c73fed03683823bd6e72757ed993dd32527de3d5f2b7a64bb031b9
)
vcpkg_extract_source_archive(${CLANG_ARCHIVE} ${SOURCE_PATH}/tools)

if(NOT EXISTS ${SOURCE_PATH}/tools/clang)
  file(RENAME ${SOURCE_PATH}/tools/cfe-6.0.1.src ${SOURCE_PATH}/tools/clang)
endif()

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES ${CMAKE_CURRENT_LIST_DIR}/install-cmake-modules-to-share.patch
)

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
set(ENV{PATH} "$ENV{PATH};${PYTHON3_DIR}")

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DLLVM_TARGETS_TO_BUILD=X86
        -DLLVM_INCLUDE_TOOLS=ON
        -DLLVM_INCLUDE_UTILS=OFF
        -DLLVM_INCLUDE_EXAMPLES=OFF
        -DLLVM_INCLUDE_TESTS=OFF
        -DLLVM_ABI_BREAKING_CHECKS=FORCE_OFF
        -DLLVM_TOOLS_INSTALL_DIR=tools/llvm
)

vcpkg_install_cmake()

file(GLOB EXE ${CURRENT_PACKAGES_DIR}/bin/*)
file(GLOB DEBUG_EXE ${CURRENT_PACKAGES_DIR}/debug/bin/*)
file(COPY ${EXE} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/llvm)
file(COPY ${DEBUG_EXE} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/tools/llvm)
file(REMOVE ${EXE})
file(REMOVE ${DEBUG_EXE})

vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/clang TARGET_PATH share/clang)
vcpkg_fixup_cmake_targets(CONFIG_PATH share/llvm)
vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/llvm)

file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/debug/include
    ${CURRENT_PACKAGES_DIR}/debug/tools
    ${CURRENT_PACKAGES_DIR}/debug/share
    ${CURRENT_PACKAGES_DIR}/debug/bin
    ${CURRENT_PACKAGES_DIR}/debug/msbuild-bin
    ${CURRENT_PACKAGES_DIR}/bin
    ${CURRENT_PACKAGES_DIR}/msbuild-bin
    ${CURRENT_PACKAGES_DIR}/tools/msbuild-bin
    ${CURRENT_PACKAGES_DIR}/include/llvm/BinaryFormat/WasmRelocs
)

# Remove one empty include subdirectory if it is indeed empty
file(GLOB MCANALYSISFILES ${CURRENT_PACKAGES_DIR}/include/llvm/MC/MCAnalysis/*)
if(NOT MCANALYSISFILES)
  file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/include/llvm/MC/MCAnalysis)
endif()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE.TXT DESTINATION ${CURRENT_PACKAGES_DIR}/share/llvm RENAME copyright)
