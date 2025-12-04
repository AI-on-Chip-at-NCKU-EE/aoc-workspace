#!/bin/bash

set -e

help() {
    cat <<EOF

Usage: eman <command>

Environment Manager for Docker

Available commands:

  eman help                       : show this help message

  eman c-compiler-version        : print the version of default C compiler and the version of GNU Make
  eman c-compiler-example        : compile and run the C/C++ example(s)

  eman verilator-version         : print the version of the first found Verilator
  eman verilator-example         : compile and run the Verilator example(s)

  eman tvm-version               : print TVM version and environment variables
  eman python-version            : print Python version
  eman ml-packages-version       : print versions of ML packages (ONNX, PyTorch, etc.)

  eman check-all                 : check all tools and packages versions

EOF
}

c_compiler_version() {
    echo "[C Compiler Version]"
    gcc --version | head -n 1
    echo "[Make Version]"
    make --version | head -n 1
}

c_compiler_example() {
    echo "[C Compiler Example]"
    cd "${HOME}"/test/c-compiler
    make
}

check_verilator() {
    echo "[Verilator Version]"
    if ! command -v verilator >/dev/null 2>&1; then
        echo "Verilator not found!"
        exit 1
    fi
    verilator --version
}

verilator_example() {
    echo "[Verilator Example]"
    cd "${HOME}"/test/verilator
    make
}

tvm_version() {
    echo "[TVM Version]"
    if ! python3 -c "import tvm" 2>/dev/null; then
        echo "TVM not found!"
        exit 1
    fi
    python3 -c "import tvm; print(f'TVM version: {tvm.__version__}')"
    echo "[TVM Environment]"
    echo "TVM_HOME: ${TVM_HOME:-Not set}"
    echo "PYTHONPATH: ${PYTHONPATH:-Not set}"
}

python_version() {
    echo "[Python Version]"
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Python3 not found!"
        exit 1
    fi
    python3 --version
    echo "[Pip Version]"
    if ! command -v pip3 >/dev/null 2>&1; then
        echo "Pip3 not found!"
        exit 1
    fi
    pip3 --version
}

ml_packages_version() {
    echo "[ML Packages Version]"
    python3 << 'EOF'
packages = ['onnx', 'onnxruntime', 'torch', 'torchvision', 'numpy']
for pkg in packages:
    try:
        module = __import__(pkg)
        print(f'{pkg.capitalize()}: {module.__version__}')
    except ImportError:
        print(f'{pkg.capitalize()}: Not installed')
EOF
}

check_all() {
    local FAILED=false

    echo "=== Environment Check - All Tools ==="
    echo ""
    (c_compiler_version) || FAILED=true
    echo ""
    (check_verilator) || FAILED=true
    echo ""
    (python_version) || FAILED=true
    echo ""
    (tvm_version) || FAILED=true
    echo ""
    (ml_packages_version) || FAILED=true
    echo ""
    echo "=== All checks completed ==="
    echo ""

    if [ "$FAILED" = "false" ]; then
        cat /usr/local/share/eman/celebration.txt 2>/dev/null || echo "Environment setup complete!"
    fi
}


# === Main Dispatcher ===
case "$1" in
    help|"")
        help
        ;;
    c-compiler-version)
        c_compiler_version
        ;;
    c-compiler-example)
        c_compiler_example
        ;;
    verilator-version)
        check_verilator
        ;;
    verilator-example)
        verilator_example
        ;;
    tvm-version)
        tvm_version
        ;;
    python-version)
        python_version
        ;;
    ml-packages-version)
        ml_packages_version
        ;;
    check-all)
        check_all
        ;;
    *)
        echo "Unknown command: $1"
        help
        exit 1
        ;;
esac
