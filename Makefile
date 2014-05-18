THEOS_PACKAGE_DIR_NAME = debs
TWEAK_NAME = AppSyncUnified
IPHONE_ARCHS = armv7 armv7s arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0
DEBUG = 0

include $(THEOS)/makefiles/common.mk

AppSyncUnified_FILES = AppSyncUnified.x
AppSyncUnified_CFLAGS = -fvisibility=hidden
AppSyncUnified_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

package::
	dpkg-deb -b -Zgzip transitional/nodelete-net.angelxwind.appsync70plus
	dpkg-deb -b -Zgzip transitional/nodelete-net.angelxwind.appsync60plus
	dpkg-deb -b -Zgzip transitional/nodelete-net.angelxwind.appsync50plus
	mv transitional/nodelete-net.angelxwind.appsync*plus.deb debs/

clean::
	rm -f debs/nodelete-net.angelxwind.appsync*plus.deb