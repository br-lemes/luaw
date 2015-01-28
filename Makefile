
LUA_VERSION=5.2.3

CC=arm-linux-androideabi-gcc
STRIP=arm-linux-androideabi-strip

LUA=lua-$(LUA_VERSION)/src/lua
LUA_D=lua-$(LUA_VERSION)
LUA_TGZ=downloads/lua-$(LUA_VERSION).tar.gz

all: $(LUA)

all-download: $(LUA_TGZ)

$(LUA): $(LUA_D)
	@$(MAKE) -C lua-$(LUA_VERSION)/src liblua52.so LUA_A=liblua52.so \
		"AR=$(CC) -Wl,-E -shared -o" RANLIB="$(STRIP)" CC="$(CC)" \
		MYCFLAGS="'-Dgetlocaledecpoint()=46'"
	@$(MAKE) -C lua-$(LUA_VERSION)/src all CC="$(CC)" \
		MYCFLAGS="'-Dgetlocaledecpoint()=46' \
		-DLUA_USE_POSIX -DLUA_USEDLOPEN" MYLIBS="-Wl,-E -ldl" MYLDFLAGS=-s
	@$(STRIP) $@

$(LUA_D): $(LUA_TGZ)
	@tar xf $<
	@touch $@

$(LUA_TGZ):
	@mkdir -p downloads
	@wget -c http://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz -O $@.part
	@mv $@.part $@

clean:
	@$(RM) -r $(LUA_D)

clean-downloads: clean
	@$(RM) -r downloads
