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

  eman systemc-example           : compile and run a systmec code which shows the version

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

systemc_example() {
    echo "[System C Example]"
    cd "${HOME}"/test/systemc
    make
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
    systemc-example)
        systemc_example
        ;;
    *)
        echo "Unknown command: $1"
        help
        exit 1
        ;;
esac
