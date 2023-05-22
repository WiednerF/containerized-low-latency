#!/bin/bash
# Script based on https://github.com/gallenmu/latency-limbo/


DEFAULT_BUCKET_SIZE=100   # default bucket size of the histogram
DEFAULT_TRIM_MS=0         # default cut the first TRIM_MS ms from evaluation
DEFAULT_NUM_WORST=5000    # default number of worst latencies to evaluate


BASENAME="$(readlink -f "$0")"
BASEDIR="$(dirname "$BASENAME")"
BASENAME="$(basename "$BASENAME")"

PYTHON=$HOME/.venv/bin/python3

[[ -x "$PYTHON" ]] || PYTHON=python3


log () {
	printf "%s\n" "$*" >&2
}

err() {
	log "$*"
	exit 2
}

help() {
	err usage: "$BASENAME" capturename
}

analysis() {
	local name="$1"

	[[ -e "$name" ]] && name="$(realpath "$name")"

	local bname="$(basename "$name")"

	# histogram
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "bucket_size=$BUCKET_SIZE" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/latency-hist.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.hist.csv"

	# worst-of-latency
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -v "num_worst=$NUM_WORST" -f "$BASEDIR/sql/evaluation/dump-worst.sql" > "${bname}.trim_ms$TRIM_MS.num_worst$NUM_WORST.worst.csv"

	# percentiles (hdr)
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/dump-percentiles.sql" > "${bname}.trim_ms$TRIM_MS.percentiles.csv"

	# throughput
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/dump-transferrate.sql" > "${bname}.trim_ms$TRIM_MS.transferrate.csv"

	# packetrate
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -v "type=pre" -f "$BASEDIR/sql/evaluation/dump-packetrate.sql" > "${bname}.trim_ms$TRIM_MS.packetratepre.csv"
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -v "type=post" -f "$BASEDIR/sql/evaluation/dump-packetrate.sql" > "${bname}.trim_ms$TRIM_MS.packetratepost.csv"

	# stats
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/stats.sql" > "${bname}.trim_ms$TRIM_MS.stats.csv"

	# all-latencies
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "trim_ms=$TRIM_MS" -f "$BASEDIR/sql/evaluation/latency-ts.sql" > "${bname}.trim_ms$TRIM_MS.latency-ts.csv"

	# inter-packet gap jitter histogram
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "bucket_size=$BUCKET_SIZE" -v "trim_ms=$TRIM_MS" -v "type=pre" -f "$BASEDIR/sql/evaluation/jitter-hist.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.jitterpre.csv"
	psql -q -X -v ON_ERROR_STOP=1 -v "name=$name" -v "bucket_size=$BUCKET_SIZE" -v "trim_ms=$TRIM_MS" -v "type=post" -f "$BASEDIR/sql/evaluation/jitter-hist.sql" > "${bname}.bucket_size$BUCKET_SIZE.trim_ms$TRIM_MS.jitterpost.csv"
}

test $# -lt 1 && help

analysis "$@"
