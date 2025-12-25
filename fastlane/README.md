fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios deploy_to_testflight

```sh
[bundle exec] fastlane ios deploy_to_testflight
```

Deploy to TestFlight

### ios run_unit_tests

```sh
[bundle exec] fastlane ios run_unit_tests
```

Run unit tests

### ios _bump_build

```sh
[bundle exec] fastlane ios _bump_build
```

Increment build number

### ios _build_app_for_testflight

```sh
[bundle exec] fastlane ios _build_app_for_testflight
```

Build and archive the app

### ios _upload_build

```sh
[bundle exec] fastlane ios _upload_build
```

Upload to TestFlight

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

Create app in App Store Connect

### ios test

```sh
[bundle exec] fastlane ios test
```

Run tests only

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
