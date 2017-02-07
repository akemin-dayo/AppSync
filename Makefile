THEOS_PACKAGE_DIR_NAME = debs
TWEAK_NAME = AppSyncUnified
IPHONE_ARCHS = armv7 armv7s arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 5.0
DEBUG = 1
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk
SUBPROJECTS += AppSyncUnified
SUBPROJECTS += postinst
SUBPROJECTS += asu_inject
include $(THEOS_MAKE_PATH)/aggregate.mk

package::
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsync70plus debs/net.angelxwind.appsync70plus.deb
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsync60plus debs/net.angelxwind.appsync60plus.deb
	@$(_THEOS_PLATFORM_DPKG_DEB) -b -Zgzip transitional/nodelete-net.angelxwind.appsync50plus debs/net.angelxwind.appsync50plus.deb

clean::
	@rm -f debs/*.deb
