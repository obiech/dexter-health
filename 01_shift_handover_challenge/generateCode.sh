#!/bin/bash
set -e

flutter clean
flutter pub get
dart pub run build_runner build --delete-conflicting-outputs