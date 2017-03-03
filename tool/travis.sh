#!/bin/bash

# Fast fail the script on failures.
set -e

# Analyze the code.
dartanalyzer --fatal-warnings \
  lib/image.dart \
  test/image_test.dart

# Run the tests.
dart -c test/image_test.dart
