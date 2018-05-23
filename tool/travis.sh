#!/bin/bash

# Fast fail the script on failures.
set -e

# Analyze the code.
dartanalyzer --fatal-warnings lib/image.dart

# Run the tests.
pub run build_runner test
