PROJECT := Corral.xcodeproj
SCHEME := Corral
CONFIGURATION := Debug
DERIVED_DATA := tmp/DerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/FinderOne.app

.PHONY: build clean-build run clean

build:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		build CODE_SIGNING_ALLOWED=NO

clean-build:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		clean build CODE_SIGNING_ALLOWED=NO

run:
	open $(APP_PATH)

clean:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) \
		clean CODE_SIGNING_ALLOWED=NO
