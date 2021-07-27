#!/bin/bash

pushd wasm-micro-runtime/wamr-compiler
./build_llvm.sh
mkdir build
pushd build
cmake ..
make
popd
cmake -DWAMR_BUILD_PLATFORM=linux -DWAMR_BUILD_TARGET=X86_64
cd product-mini/platforms/linux/
mkdir build
cd build
cmake ..
make
popd
