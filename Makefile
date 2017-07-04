DEBUG = 0
PACKAGE_VERSION = 1.1

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:8.0
	ARCHS = x86_64 i386
else
	TARGET = iphone:clang:latest:7.0
endif

include $(THEOS)/makefiles/common.mk
TWEAK_NAME = InternalPhotos
InternalPhotos_FILES = Tweak.xm
InternalPhotos_FRAMEWORKS = UIKit
InternalPhotos_PRIVATE_FRAMEWORKS = AppSupport PhotoLibrary
InternalPhotos_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/tweak.mk

all::
ifeq ($(SIMULATOR),1)
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject
endif
