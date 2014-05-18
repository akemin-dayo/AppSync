THEOS_PACKAGE_DIR_NAME = debs
TWEAK_NAME = AppSyncUnified
IPHONE_ARCHS = armv7 armv7s arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0
DEBUG = 0

include $(THEOS)/makefiles/common.mk

AppSyncUnified_FILES = Tweak.x
AppSyncUnified_CFLAGS = -fvisibility=hidden
AppSyncUnified_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

package::
	dpkg -b transitional/net.angelxwind.appsync70plus
	dpkg -b transitional/net.angelxwind.appsync60plus
	dpkg -b transitional/net.angelxwind.appsync50plus
	mv transitional/net.angelxwind.appsync*plus.deb debs/