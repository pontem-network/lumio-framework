
## The Lumio Framework

The Lumio Framework defines the standard actions that can be performed on-chain
both by the Lumio VM---through the various prologue/epilogue functions---and by
users of the blockchain---through the allowed set of transactions. This
directory contains different directories that hold the source Move
modules and transaction scripts, along with a framework for generation of
documentation, ABIs, and error information from the Move source
files. See the [Layout](#layout) section for a more detailed overview of the structure.

## Documentation

Each of the main components of the Lumio Framework and contributing guidelines are documented separately.

## Compilation and Generation

The documents above were created by the Move documentation generator for Lumio. It is available as part of the Lumio CLI. To see its options, run:
```shell
lumio move document --help
```

The documentation process is also integrated into the framework building process and will be automatically triggered like other derived artifacts, via `cached-packages` or explicit release building.

## Running Move tests

To test our Move code while developing the Lumio Framework, run `cargo test` inside this directory:

```
cargo test
```

(Alternatively, run `cargo test -p lumio-framework` from anywhere.)

To skip the Move prover tests, run:

```
cargo test -- --skip prover
```

To filter and run only the tests in specific packages (e.g., `lumio_stdlib`), run:

```
cargo test -- lumio_stdlib --skip prover
```

(See tests in `tests/move_unit_test.rs` to determine which filter to use; e.g., to run the tests in `lumio_framework` you must filter by `move_framework`.)

Sometimes, Rust runs out of stack memory in dev build mode.  You can address this by either:
1. Adjusting the stack size

```
export RUST_MIN_STACK=4297152
```

2. Compiling in release mode

```
cargo test --release -- --skip prover
```

## Layout
The overall structure of the Lumio Framework is as follows:

```
├── lumio-framework                                 # Sources, testing and generated documentation for lumio framework component
├── lumio-token                                 # Sources, testing and generated documentation for lumio token component
├── lumio-stdlib                                 # Sources, testing and generated documentation for lumio stdlib component
├── move-stdlib                                 # Sources, testing and generated documentation for Move stdlib component
├── cached-packages                                 # Tooling to generate SDK from mvoe sources.
├── src                                     # Compilation and generation of information from Move source files in the Lumio Framework. Not designed to be used as a Rust library
├── releases                                    # Move release bundles
└── tests
```
