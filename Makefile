PROJECT := Corral.xcodeproj
SCHEME := Corral
CONFIGURATION := Release
DERIVED_DATA := tmp/DerivedData
DIST_DIR := dist
APP_PATH := $(DIST_DIR)/FinderOne.app

.PHONY: build clean-build run clean debug-build

build:
	CONFIGURATION=$(CONFIGURATION) \
	DERIVED_DATA=$(DERIVED_DATA) \
	./scripts/build-app.sh

clean-build:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		clean CODE_SIGNING_ALLOWED=NO
	CONFIGURATION=$(CONFIGURATION) \
	DERIVED_DATA=$(DERIVED_DATA) \
	./scripts/build-app.sh

debug-build:
	CONFIGURATION=Debug \
	DERIVED_DATA=$(DERIVED_DATA) \
	./scripts/build-app.sh

run:
	open $(APP_PATH)

clean:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		clean CODE_SIGNING_ALLOWED=NO
