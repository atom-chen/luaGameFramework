APP_STL := gnustl_static

# -DCC_ENABLE_CHIPMUNK_INTEGRATION=1
APP_CPPFLAGS := -frtti -std=c++11 -fsigned-char -DHAVE_OPENSSL
APP_LDFLAGS := -latomic

APP_ABI := armeabi-v7a
# developers report it will cause error on Windows
# APP_SHORT_COMMANDS := true


ifeq ($(NDK_DEBUG),1)
  APP_CPPFLAGS += -DCOCOS2D_DEBUG=1
  APP_OPTIM := debug
else
  APP_CPPFLAGS += -DNDEBUG
  APP_OPTIM := release
endif
