#!/usr/bin/env bash
# Convert a directory of hMETIS .hgr files for several MPI process counts.
set -euo pipefail

usage() {
  echo "Usage: $0 INPUT_DIR OUTPUT_DIR PE_COUNT [PE_COUNT ...]"
  echo "Reads *.hgr files directly in INPUT_DIR; writes OUTPUT_DIR/PE_COUNT/*.bin-RANK."
  echo "Set PARKWAY_CONVERTER to override the converter executable."
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  usage
  exit 0
fi
if (( $# < 3 )); then usage >&2; exit 1; fi
input=$1
output=$2
shift 2
[[ -d $input ]] || { echo "Input directory does not exist: $input" >&2; exit 1; }
for pe in "$@"; do
  [[ $pe =~ ^[1-9][0-9]*$ ]] || { echo "Invalid PE count: $pe" >&2; exit 1; }
done
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
converter=${PARKWAY_CONVERTER:-"$script_dir/../bin/parkway_hypergraph_converter"}
[[ -x $converter ]] || { echo "Build the converter first: cmake --build build --target parkway_hypergraph_converter" >&2; exit 1; }
shopt -s nullglob
graphs=("$input"/*.hgr)
(( ${#graphs[@]} )) || { echo "No .hgr files found in $input" >&2; exit 1; }
mkdir -p -- "$output"
work=$(mktemp -d "${TMPDIR:-/tmp}/parkway-convert.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT

for graph in "${graphs[@]}"; do
  name=${graph##*/}
  cp -- "$graph" "$work/$name"
  echo "Converting $name"
  "$converter" -form 1 -matrix 0 "$work/$name"
  [[ -s $work/$name.bin ]] || { echo "Conversion failed: $graph" >&2; exit 1; }
  for pe in "$@"; do
    echo "  Splitting for $pe PEs"
    "$converter" -form 9 -matrix 0 -np "$pe" "$work/$name.bin"
    mkdir -p -- "$output/$pe"
    for ((rank=0; rank<pe; rank++)); do
      [[ -s $work/$name.bin-$rank ]] || { echo "Missing rank file: $name.bin-$rank" >&2; exit 1; }
      mv -- "$work/$name.bin-$rank" "$output/$pe/"
    done
  done
  rm -- "$work/$name" "$work/$name.bin"
done
