# Par<i>k</i>way

Parallel hypergraph partitioning in C++ using MPI.

[![Build Status](https://travis-ci.org/parkway-partitioner/parkway.svg)](https://travis-ci.org/parkway-partitioner/parkway)

## Disclaimer

Copyright (C) 2004 Aleksandar Trifunovic

This program is free software; Redistribution and modification of any part or
all of the program without explicit permission from the author is strictly
forbidden.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

## Minimum Requirements

* [CMake](http://cmake.org/) 3.16
* C++11 compliant compiler (tested with Clang 3.6, GCC 4.8.2, GCC 5.1.0;
  minimum supported GCC version is 4.8.x)
* MPI (tested with MPICH 3.0.4 and MPICH 3.1.4)

## Building

Boost 1.88.0 is downloaded using CMake FetchContent and built with the project
by default. No system installation or sudo is required. The first configure
needs internet access; sources are cached under `build/_deps`. Only the required
Boost libraries and their dependencies are built.

```sh
cmake -S . -B build
cmake --build build -j 4
```

To use an installed Boost instead, configure with `-DPARKWAY_FETCH_BOOST=OFF`.
For an offline build, supply an extracted Boost CMake distribution using
`-DFETCHCONTENT_SOURCE_DIR_BOOST=/path/to/boost-1.88.0`.

Run the `configure` script with any additional CMake arguments (i.e. to select
a generator). Parkway options are as such:

* `-D PARKWAY_TESTS=<true|false>` to add support for building and running unit
  tests.

Assuming a UNIX system using GNU Makefiles, once configured `make help` will
list all build targets. A number of targets are:

* `make parkway` - builds `libparkway`.
* `make parkway_driver` - builds a utility to partition hypergraphs using
  `libparkway`.
* `make` - builds the above and a few more utilities.

## Partitioning an hMETIS hypergraph

The driver reads ParKWay binary files, one per MPI rank. Convert an hMETIS text
file and split it for the desired number of MPI processes before running:

```sh
bin/parkway_hypergraph_converter -form 1 -matrix 0 graph.hgr
bin/parkway_hypergraph_converter -form 9 -matrix 0 -np 2 graph.hgr.bin
mpirun -np 2 bin/parkway_driver --hypergraph graph.hgr.bin --number-of-parts 4
```

The first command creates `graph.hgr.bin`; the second creates
`graph.hgr.bin-0` and `graph.hgr.bin-1`. Pass the base filename to the driver.
Regenerate the split files when changing the number of MPI processes.
The number of output partitions is independent of the number of processes.
The converter accepts hMETIS weight flags `0`, `1`, `10`, and `11`, with
vertex IDs starting at 1. Use `-matrix 0` for a general hypergraph.

To prepare every `*.hgr` file directly in a directory for several PE counts:

```sh
utilities/convert_hypergraphs.sh input/ converted/ 1 2 4 8
mpirun -np 4 bin/parkway_driver --hypergraph converted/4/graph.hgr.bin --number-of-parts 4
```

This creates `converted/1/`, `converted/2/`, etc., each containing the rank files
for that process count. Input files are left untouched; existing output files
with the same names are overwritten. Set `PARKWAY_CONVERTER` to use a converter
executable from another build.
