#!/bin/zsh

set -euo pipefail

PROJECT="${PROJECT:-Corral.xcodeproj}"
SCHEME="${SCHEME:-Corral}"
CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-tmp/DerivedData}"
DIST_DIR="${DIST_DIR:-dist}"
APP_NAME="${APP_NAME:-FinderOne}"
APP_VERSION="${APP_VERSION:-}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
BUILD_ARCH="${BUILD_ARCH:-arm64}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"

APP_PATH="$DIST_DIR/$APP_NAME.app"

mkdir -p "$DIST_DIR"

XCODEBUILD_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -derivedDataPath "$DERIVED_DATA"
  -arch "$BUILD_ARCH"
  build
  ONLY_ACTIVE_ARCH=YES
  CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED"
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
)

if [[ -n "$APP_VERSION" ]]; then
  XCODEBUILD_ARGS+=("MARKETING_VERSION=$APP_VERSION")
fi

if [[ -n "$DEVELOPMENT_TEAM" ]]; then
  XCODEBUILD_ARGS+=("DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM")
fi

if [[ -n "$CODE_SIGN_IDENTITY" ]]; then
  XCODEBUILD_ARGS+=("CODE_SIGN_IDENTITY=$CODE_SIGN_IDENTITY")
fi

echo "Building $APP_NAME.app"
echo "  configuration: $CONFIGURATION"
echo "  arch: $BUILD_ARCH"
echo "  derived data: $DERIVED_DATA"
echo "  code signing: $CODE_SIGNING_ALLOWED"

xcodebuild "${XCODEBUILD_ARGS[@]}"

BUILT_APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"

if [[ ! -d "$BUILT_APP_PATH" ]]; then
  echo "Built app not found at $BUILT_APP_PATH" >&2
  exit 1
fi

rm -rf "$APP_PATH"
cp -R "$BUILT_APP_PATH" "$APP_PATH"

echo "App copied to $APP_PATH"
