#!/bin/sh
set -eu

curl --fail --silent "http://127.0.0.1:${PORT:-10000}/up"
