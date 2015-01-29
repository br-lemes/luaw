
LUA_VERSION=5.2.3

CC=arm-linux-androideabi-gcc
STRIP=arm-linux-androideabi-strip

LUA=lua-$(LUA_VERSION)/src/lua
LUA_D=lua-$(LUA_VERSION)
LUA_HD=lua-host/$(LUA_D)
LUA_TGZ=downloads/lua-$(LUA_VERSION).tar.gz
LUA_HOST=lua-host/lua-$(LUA_VERSION)/src/lua

all: $(LUA) $(LUA_HOST)

all-download: $(LUA_TGZ)

$(LUA): $(LUA_D)
	@$(MAKE) -C lua-$(LUA_VERSION)/src liblua52.so LUA_A=liblua52.so \
		"AR=$(CC) -Wl,-E -shared -o" RANLIB="$(STRIP)" CC="$(CC)" \
		MYCFLAGS="'-Dgetlocaledecpoint()=46'"
	@$(MAKE) -C lua-$(LUA_VERSION)/src all CC="$(CC)" \
		MYCFLAGS="'-Dgetlocaledecpoint()=46' \
		-DLUA_USE_POSIX -DLUA_USEDLOPEN" MYLIBS="-Wl,-E -ldl" MYLDFLAGS=-s
	@$(STRIP) $@

$(LUA_HOST): $(LUA_HD)
	@$(MAKE) -C lua-host/lua-$(LUA_VERSION)/src liblua.a

$(LUA_HD): $(LUA_TGZ)
	@mkdir -p lua-host
	@tar xf $< -C lua-host
	@touch $@

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
