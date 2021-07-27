CC=clang
OPTFLAGS=-O3 -flto

ROOT_PATH:=$(realpath .)

WASM_CC:=${ROOT_PATH}/wasi-sdk/bin/clang
WASI_SDK_SYSROOT:=${ROOT_PATH}/wasi-sdk/share/wasi-sysroot
WASM_FLAGS:=--target=wasm32-wasi -mcpu=mvp ${OPTFLAGS} --sysroot=${WASI_SDK_SYSROOT}
WASM_LINKER_FLAGS:=-Wl,--threads=1,-z

./wasm-micro-runtime/product-mini/platforms/linux/build/iwasm:
	cd wasm-micro-runtime && cmake -DWAMR_BUILD_PLATFORM=linux -DWAMR_BUILD_TARGET=X86_64 && cd product-mini/platforms/linux/ && mkdir -p build && cd build && cmake .. && make

./wasm-micro-runtime/wamr-compiler/build/wamrc:
	cd wasm-micro-runtime/wamr-compiler && ./build_llvm.sh && mkdir -p build && cd build && cmake .. && make

./WAVM/bin/wavm:
	cd WAVM && cmake . && make 

.PHONY: prep_wavm_cache
prep_wavm_cache:
	mkdir -p wavm_cache

./aWsm/target/release/awsm:
	cd aWsm && cargo build --release

clean:
	rm -rf resize resize.wasm resize.bc resize_vm resize.jpg res

resize.wasm: ./sod/sod.c ./sod/samples/resize_image.c
	${WASM_CC} ${WASM_FLAGS} ${WASM_LINKER_FLAGS} -D_WASI_EMULATED_MMAN -lwasi-emulated-mman -lm -I./sod -Wall ./sod/sod.c ./sod/samples/resize_image.c -o resize.wasm

resize: ./sod/sod.c ./sod/samples/resize_image.c 
	${CC} ${OPTFLAGS} -I./sod -lm -Wall ./sod/sod.c ./sod/samples/resize_image.c -o resize

resize.bc: ./aWsm/target/release/awsm resize.wasm
	./aWsm/target/release/awsm resize.wasm -o resize.bc

resize_vm: resize.bc ./aWsm/runtime/runtime.c ./aWsm/runtime/libc/wasi_sdk_backing.c ./aWsm/runtime/libc/env.c ./aWsm/runtime/memory/64bit_nix.c
	clang ${OPTFLAGS} -lm resize.bc ./aWsm/runtime/runtime.c ./aWsm/runtime/libc/wasi_sdk_backing.c ./aWsm/runtime/libc/env.c ./aWsm/runtime/memory/64bit_nix.c -o resize_vm

resize.wavm:
	./WAVM/bin/wavm compile ./resize.wasm resize.wavm

.PHONY: resize_wasmtime
resize_wasmtime: resize.wasm
	wasmtime resize.wasm <./sod/samples/flower.jpg >resize.jpg


.PHONY: resize_awsm
resize_awsm: resize_vm
	./resize_vm <./sod/samples/flower.jpg >resize.jpg

resize.wamr:
	./wasm-micro-runtime/wamr-compiler/build/wamrc -o resize.wamr ./resize.wasm

.PHONY: bench
bench: ./wasm-micro-runtime/wamr-compiler/build/wamrc ./wasm-micro-runtime/product-mini/platforms/linux/build/iwasm ./WAVM/bin/wavm resize.wasm resize.wavm prep_wavm_cache resize_vm resize
	mkdir -p res
	WAVM_OBJECT_CACHE_DIR=${ROOT_PATH}/wavm_cache \
	hyperfine --warmup 3 --export-markdown results.md \
	-n wasmtime 'wasmtime resize.wasm <./sod/samples/flower.jpg >./res/resize_wasmtime.jpg' \
	-n wavm './WAVM/bin/wavm run resize.wavm <./sod/samples/flower.jpg >./res/resize_wavm.jpg' \
	-n wamr './wasm-micro-runtime/product-mini/platforms/linux/build/iwasm resize.wamr <./sod/samples/flower.jpg >./res/resize_wamr.jpg' \
	-n awsm './resize_vm <./sod/samples/flower.jpg >./res/resize_awsm.jpg' \
	-n native './resize <./sod/samples/flower.jpg >./res/resize_native.jpg'
	pandoc -o results.pdf results.md 
