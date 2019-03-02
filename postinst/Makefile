include $(THEOS)/makefiles/common.mk

TOOL_NAME = postinst prerm

postinst_FILES = postinst.c
postinst_CFLAGS += -fvisibility=hidden -DPOSTINST
postinst_FRAMEWORKS = CoreFoundation
postinst_INSTALL_PATH = /DEBIAN
postinst_CODESIGN_FLAGS = -S../entitlements.xml

prerm_FILES = postinst.c
prerm_CFLAGS += -fvisibility=hidden
prerm_FRAMEWORKS = CoreFoundation
prerm_INSTALL_PATH = /DEBIAN
prerm_CODESIGN_FLAGS = -S../entitlements.xml

include $(THEOS_MAKE_PATH)/tool.mk
