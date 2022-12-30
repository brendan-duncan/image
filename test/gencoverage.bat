dart run test --coverage=out\coverage
dart pub global run coverage:format_coverage --packages=.dart_tool\package_config.json --report-on=lib --lcov -o .\out\coverage\lcov.info -i out\coverage
rem npm install -g @lcov-viewer/cli
lcov-viewer lcov -o out\coverage\html out\coverage\lcov.info
