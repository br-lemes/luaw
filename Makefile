
LUA_VERSION=5.2.3
HASERL_VERSION=0.9.33
BUSYBOX_VERSION=1.23.1

CC=arm-linux-androideabi-gcc
STRIP=arm-linux-androideabi-strip

LUA_D=lua-$(LUA_VERSION)
LUA=$(LUA_D)/src/lua
LUA_HD=lua-host/$(LUA_D)
LUA_TGZ=downloads/$(LUA_D).tar.gz
LUA_HOST=lua-host/$(LUA_D)/src/lua

HASERL_D=haserl-$(HASERL_VERSION)
HASERL=$(HASERL_D)/src/haserl
HASERL_TGZ=downloads/$(HASERL_D).tar.gz
HASERL_LUA2C=$(HASERL_D)/src/lua2c
HASERL_MAKEFILE=$(HASERL_D)/Makefile

BUSYBOX_D=busybox-$(BUSYBOX_VERSION)
BUSYBOX=$(BUSYBOX_D)/busybox
BUSYBOX_TGZ=downloads/$(BUSYBOX_D).tar.bz2
BUSYBOX_CONFIG=$(BUSYBOX_D)/.config

export LUA_CFLAGS=-I$(PWD)/$(LUA_D)/src/
export LUA_LIBS=-L$(PWD)/$(LUA_D)/src/ -llua -lm

all: $(LUA) $(LUA_HOST) $(HASERL) $(BUSYBOX)

all-download: $(LUA_TGZ) $(HASERL_TGZ) $(BUSYBOX_TGZ)

$(LUA): $(LUA_D)
	@$(MAKE) -C $(LUA_D)/src liblua52.so LUA_A=liblua52.so \
		"AR=$(CC) -Wl,-E -shared -o" RANLIB="$(STRIP)" CC="$(CC)" \
		MYCFLAGS="'-Dgetlocaledecpoint()=46'"
	@$(MAKE) -C $(LUA_D)/src all CC="$(CC)" \
		MYCFLAGS="'-Dgetlocaledecpoint()=46' \
		-DLUA_USE_POSIX -DLUA_USEDLOPEN" MYLIBS="-Wl,-E -ldl" MYLDFLAGS=-s
	@$(STRIP) $@

$(LUA_HOST): $(LUA_HD)
	@$(MAKE) -C lua-host/$(LUA_D)/src liblua.a

$(LUA_HD): $(LUA_TGZ)
	@mkdir -p lua-host
	@tar xf $< -C lua-host
	@touch $@

$(LUA_D): $(LUA_TGZ)
	@tar xf $<
	@touch $@

$(LUA_TGZ):
	@mkdir -p downloads
	@wget -c http://www.lua.org/ftp/$(LUA_D).tar.gz -O $@.part
	@mv $@.part $@

$(HASERL): $(HASERL_LUA2C) $(HASERL_MAKEFILE)
	@$(MAKE) -C $(HASERL_D)
	@$(STRIP) $@

$(HASERL_LUA2C): $(LUA_HOST) $(HASERL_D)
	@gcc -o $@ $@.c -I $(PWD)/lua-host/$(LUA_D)/src \
		-L $(PWD)/lua-host/$(LUA_D)/src -llua -lm

$(HASERL_MAKEFILE):
	@$(MAKE) $(HASERL_D)
	@cd $(HASERL_D) && ./configure \
		--prefix=/usr \
		--host=arm-linux-androideabi \
		--with-lua=lua5.2

$(HASERL_D): $(HASERL_TGZ)
	@tar xf $<
	@touch $@

$(HASERL_TGZ):
	@mkdir -p downloads
	@wget -c http://sourceforge.net/projects/haserl/files/haserl-devel/$(HASERL_D).tar.gz -O $@.part
	@mv $@.part $@

$(BUSYBOX): $(BUSYBOX_CONFIG)
	@ARCH="arm" CROSS_COMPILE="arm-linux-androideabi-" \
		$(MAKE) -C $(BUSYBOX_D) busybox

$(BUSYBOX_CONFIG): busybox-config
	@$(MAKE) $(BUSYBOX_D)
	@cp $< $@

$(BUSYBOX_D): $(BUSYBOX_TGZ)
	@tar xf $<
	@touch $@

$(BUSYBOX_TGZ):
	@mkdir -p downloads
	@wget -c http://busybox.net/downloads/$(BUSYBOX_D).tar.bz2 -O $@.part
	@mv $@.part $@

clean:
	@$(RM) -r $(LUA_D) $(LUA_HD) $(HASERL_D) $(BUSYBX_D)

clean-downloads: clean
	@$(RM) -r downloads
