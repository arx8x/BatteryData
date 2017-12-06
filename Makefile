ARCHS = armv7 arm64

include ~/theos/makefiles/common.mk

TWEAK_NAME = BatteryData
BatteryData_FILES = batterydata.xm
BatteryData_FRAMEWORKS = UIKit Preferences IOKit

include ~/theos/makefiles/tweak.mk

after-install::
	install.exec "killall -9 Preferences"
