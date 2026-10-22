APP_NAME := Headroom
BUILD_DIR := build
APP_PATH := $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app

.PHONY: build test run install zip release clean

build:
	xcodebuild -quiet \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-configuration Release \
		-destination 'generic/platform=macOS' \
		-derivedDataPath $(BUILD_DIR) \
		build

test:
	xcodebuild -quiet \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-destination 'platform=macOS' \
		-derivedDataPath $(BUILD_DIR) \
		test

run: build
	open "$(APP_PATH)"

install: build
	rm -rf "/Applications/$(APP_NAME).app"
	cp -R "$(APP_PATH)" /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

zip: build
	ditto -c -k --keepParent "$(APP_PATH)" "$(BUILD_DIR)/$(APP_NAME).zip"
	@echo "Created $(BUILD_DIR)/$(APP_NAME).zip"

release:
	scripts/release.sh

clean:
	rm -rf $(BUILD_DIR)
