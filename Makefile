PROJECT := UpNextBar.xcodeproj
SCHEME  := UpNextBar
DERIVED := build
APP     := $(DERIVED)/Build/Products/Debug/UpNextBar.app
RELEASE_APP := $(DERIVED)/Build/Products/Release/UpNextBar.app

XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED) -destination 'platform=macOS'

.PHONY: project open build test run release install dmg clean

## Generate the Xcode project from project.yml
project:
	xcodegen generate

## Open the project in Xcode
open: project
	open $(PROJECT)

## Debug build
build: project
	$(XCODEBUILD) -configuration Debug build

## Run unit tests
test: project
	$(XCODEBUILD) test

## Build and launch the app (restarts a running copy)
run: build
	-pkill -x UpNextBar
	open "$(APP)"

## Release build
release: project
	$(XCODEBUILD) -configuration Release build
	@echo "Built: $(RELEASE_APP)"

## Release build copied to /Applications (needed for reliable launch at login)
install: release
	-pkill -x UpNextBar
	rm -rf /Applications/UpNextBar.app
	cp -R "$(RELEASE_APP)" /Applications/
	open /Applications/UpNextBar.app

## Release build packaged as a drag-to-Applications disk image
dmg: release
	@version=$$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$(RELEASE_APP)/Contents/Info.plist"); \
	staging=$(DERIVED)/dmg; dmg=$(DERIVED)/UpNextBar-$$version.dmg; \
	rm -rf $$staging $$dmg && mkdir -p $$staging && \
	cp -R "$(RELEASE_APP)" $$staging/ && ln -s /Applications $$staging/Applications && \
	hdiutil create -volname "UpNext Bar $$version" -srcfolder $$staging -fs HFS+ -format UDZO -ov $$dmg >/dev/null && \
	rm -rf $$staging && echo "Built: $$dmg"

clean:
	rm -rf $(DERIVED) $(PROJECT)
