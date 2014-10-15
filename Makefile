ARCHS = armv7 armv7s arm64
SDKVERSION = 7.0
GO_EASY_ON_ME = 1

include theos/makefiles/common.mk
TWEAK_NAME = InternalPhotos
InternalPhotos_FILES = Tweak.xm
InternalPhotos_FRAMEWORKS = UIKit
InternalPhotos_PRIVATE_FRAMEWORKS = AppSupport PhotoLibrary

include $(THEOS_MAKE_PATH)/tweak.mk
