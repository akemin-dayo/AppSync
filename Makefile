THEOS_PACKAGE_DIR_NAME = debs
TWEAK_NAME = AppSyncUnified
IPHONE_ARCHS = armv7 armv7s arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0
DEBUG = 0

include $(THEOS)/makefiles/common.mk
SUBPROJECTS += AppSyncUnified
SUBPROJECTS += postinst
SUBPROJECTS += asu_inject
include $(THEOS_MAKE_PATH)/aggregate.mk

package::
	dpkg-deb -b -Zgzip transitional/nodelete-net.angelxwind.appsync70plus
	dpkg-deb -b -Zgzip transitional/nodelete-net.angelxwind.appsync60plus
	dpkg-deb -b -Zgzip transitional/nodelete-net.angelxwind.appsync50plus
	mv transitional/nodelete-net.angelxwind.appsync*plus.deb debs/

clean::
	rm -f debs/*.deb

stage::
	find "$(THEOS_STAGING_DIR)" -type f \( -iname "*.strings" -o -iname "*.plist" \) -exec plutil -convert binary1 {} \;
