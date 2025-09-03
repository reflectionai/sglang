#!/bin/bash

# This must be built within the base docker image that has the necessary dependencies installed
# gcr.io/reflectionai/mathesis-base:v20250724-0
#
# This is easily doable from Lepton machines.

set -ex

# Timing functions
START_TIME=$(date +%s)
STEP_START_TIME=""

start_timer() {
    STEP_START_TIME=$(date +%s)
    echo "===> Starting: $1 at $(date '+%Y-%m-%d %H:%M:%S')"
}

end_timer() {
    local step_end_time=$(date +%s)
    local step_duration=$((step_end_time - STEP_START_TIME))
    local minutes=$((step_duration / 60))
    local seconds=$((step_duration % 60))
    echo "===> Completed: $1 in ${minutes}m ${seconds}s"
    echo ""
}

# Overall script start
echo "========================================="
echo "SGLang Kernel Build Script (Native)"
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="
echo ""

# Configuration
start_timer "Configuration setup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SGL_THREADS=${SGL_THREADS:-8}
OUTPUT_DIR="${SCRIPT_DIR}/dist"

# Create output directory
mkdir -p ${OUTPUT_DIR}

# Set environment variables
export NVCC_APPEND_FLAGS="--threads ${SGL_THREADS}"
export TORCH_CUDA_ARCH_LIST='9.0 9.0a'
export MAX_JOBS=${SGL_THREADS}

echo "Configuration:"
echo "  - Script directory: ${SCRIPT_DIR}"
echo "  - SGL threads: ${SGL_THREADS}"
echo "  - Output directory: ${OUTPUT_DIR}"
echo "  - Python executable: ${PYTHON_BIN:-/usr/bin/app/bin/python}"
echo ""
echo "Environment variables:"
echo "  - NVCC_APPEND_FLAGS: ${NVCC_APPEND_FLAGS}"
echo "  - TORCH_CUDA_ARCH_LIST: ${TORCH_CUDA_ARCH_LIST}"
echo "  - MAX_JOBS: ${MAX_JOBS}"
end_timer "Configuration setup"

# Determine Python executable
start_timer "Python setup"
if [ -z "$PYTHON_BIN" ]; then
    if [ -f "/usr/bin/app/bin/python" ]; then
        PYTHON_BIN="/usr/bin/app/bin/python"
    elif command -v python3 &> /dev/null; then
        PYTHON_BIN="python3"
    elif command -v python &> /dev/null; then
        PYTHON_BIN="python"
    else
        echo "Error: No Python executable found!"
        exit 1
    fi
fi

echo "Using Python: ${PYTHON_BIN}"
${PYTHON_BIN} --version
end_timer "Python setup"

# Navigate to the project directory
cd ${SCRIPT_DIR}

# Build the wheel
start_timer "Wheel build"
echo "Building SGLang kernel wheel..."

${PYTHON_BIN} -m pip wheel \
    --no-cache-dir \
    --disable-pip-version-check \
    --no-build-isolation \
    -v \
    --config-settings=build-dir=build \
    --config-settings=cmake.define.SGL_KERNEL_ENABLE_FA3=OFF \
    --config-settings=cmake.define.SGL_KERNEL_ENABLE_SM90A=ON \
    --config-settings=cmake.define.ENABLE_BELOW_SM90=OFF \
    --config-settings=cmake.define.CUTLASS_NVCC_ARCHS=90 \
    --config-settings=cmake.define.CMAKE_CUDA_ARCHITECTURES=90 \
    --config-settings=cmake.define.SGL_KERNEL_ENABLE_FP8=ON \
    -w ${OUTPUT_DIR} \
    .

end_timer "Wheel build"

# Check if wheel was built successfully
start_timer "Build verification"
if ls ${OUTPUT_DIR}/sgl_kernel*.whl 1> /dev/null 2>&1; then
    echo "Build completed successfully! Wheel files:"
    ls -la ${OUTPUT_DIR}/sgl_kernel*.whl
    
    echo ""
    echo "To upload to artifact registry, run:"
    echo "python3 -m pip install keyring twine keyrings.google-artifactregistry-auth"
    echo "python3 -m twine upload --repository-url https://us-central1-python.pkg.dev/reflectionai/olympus-pypi/ ${OUTPUT_DIR}/sgl_kernel*.whl"
    
    BUILD_SUCCESS=true
else
    echo "Build failed! No wheel files found."
    BUILD_SUCCESS=false
fi
end_timer "Build verification"

# Final summary
END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))
TOTAL_MINUTES=$((TOTAL_DURATION / 60))
TOTAL_SECONDS=$((TOTAL_DURATION % 60))

echo "========================================="
echo "Build Summary"
echo "========================================="
if [ "$BUILD_SUCCESS" = true ]; then
    echo "Status: SUCCESS ✓"
    if ls ${OUTPUT_DIR}/sgl_kernel*.whl 1> /dev/null 2>&1; then
        echo "Wheel file(s):"
        for wheel in ${OUTPUT_DIR}/sgl_kernel*.whl; do
            echo "  - $(basename $wheel) ($(du -h $wheel | cut -f1))"
        done
    fi
else
    echo "Status: FAILED ✗"
fi
echo "Total build time: ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s"
echo "Completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

if [ "$BUILD_SUCCESS" = false ]; then
    exit 1
fi
