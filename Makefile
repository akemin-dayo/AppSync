include theos/makefiles/common.mk

TWEAK_NAME = AppSync
IPHONE_ARCHS = armv7 arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0

AppSync_FILES = Tweak.x
AppSync_CFLAGS = -fvisibility=hidden
AppSync_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

stage::
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/$(TWEAK_NAME).plist"
