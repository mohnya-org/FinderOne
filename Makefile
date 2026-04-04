PROJECT := Corral.xcodeproj
SCHEME := Corral
CONFIGURATION := Release
DERIVED_DATA := tmp/DerivedData
DIST_DIR := dist
APP_PATH := $(DIST_DIR)/FinderOne.app

.PHONY: build clean-build run clean debug-build

build:
	mkdir -p $(DIST_DIR)
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		-arch arm64 \
		build \
		ONLY_ACTIVE_ARCH=YES \
		CODE_SIGNING_ALLOWED=NO
	rm -rf $(APP_PATH)
	cp -R $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/FinderOne.app $(APP_PATH)

clean-build:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		clean CODE_SIGNING_ALLOWED=NO
	$(MAKE) build

debug-build:
	mkdir -p $(DIST_DIR)
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(DERIVED_DATA) \
		-arch arm64 \
		build \
		ONLY_ACTIVE_ARCH=YES \
		CODE_SIGNING_ALLOWED=NO
	rm -rf $(APP_PATH)
	cp -R $(DERIVED_DATA)/Build/Products/Debug/FinderOne.app $(APP_PATH)

run:
	open $(APP_PATH)

clean:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		clean CODE_SIGNING_ALLOWED=NO
