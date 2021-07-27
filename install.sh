#!/bin/bash

WASI_SDK_URL="https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-12/wasi-sdk-12.0-linux.tar.gz"

install_wasi_sdk() {
	wget ${WASI_SDK_URL} -O wasi-sdk.tar.gz
	tar -xvf wasi-sdk.tar.gz
	mv wasi-sdk-12.0 wasi-sdk
}

# install_awsm() {
# 	pushd aWsm
# 	./install_deb.sh
# 	popd
# }

# install_wamr() {
# 	pushd wasm-micro-runtime/wamr-compiler
# 	./build_llvm.sh
# 	mkdir build
# 	pushd build
# 	cmake ..
# 	make
# 	popd
# 	cmake -DWAMR_BUILD_PLATFORM=linux -DWAMR_BUILD_TARGET=X86_64
# 	cd product-mini/platforms/linux/
# 	mkdir build
# 	cd build
# 	cmake ..
# 	make
# 	popd
# }

install_wasmtime() {
	curl https://wasmtime.dev/install.sh -sSf | bash
}

install_hyperfine() {
	wget https://github.com/sharkdp/hyperfine/releases/download/v1.11.0/hyperfine_1.11.0_amd64.deb
	sudo dpkg -i hyperfine_1.11.0_amd64.deb
}

install_wasi_sdk
install_wasmtime
install_hyperfine
