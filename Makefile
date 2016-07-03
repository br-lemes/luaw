android:
	@mkdir -p host downloads $@
	@$(MAKE) all PREFIX=$@/ \
		SYSCFLAGS="-fPIC '-Dgetlocaledecpoint()=46' -DLUA_USE_POSIX -DLUA_USE_DLOPEN" \
		SYSLIBS="-Wl,-E -ldl -lm" \
		TRIPLE=arm-linux-androideabi \
		CC=arm-linux-androideabi-gcc \
		STRIP=arm-linux-androideabi-strip

native:
	@mkdir -p downloads $@
	@$(MAKE) all PREFIX=$@/ CC=gcc STRIP=strip \
		SYSCFLAGS="-fPIC '-Dgetlocaledecpoint()=46' -DLUA_USE_POSIX -DLUA_USE_DLOPEN" \
		SYSLIBS="-Wl,-E -ldl -lm"

LUA_VERSION=5.2.4
HASERL_VERSION=0.9.35
MONGOOSE_VERSION=5.6
SQLITE3_VERSION=3130000
SQLITE3_YEAR=2016
LUASQL_VERSION=2.3.2
LFS_VERSION=1_6_3

LUA_D=lua-$(LUA_VERSION)
LUA=$(PREFIX)$(LUA_D)/src/liblua.so
LUA_HD=host/$(LUA_D)
LUA_TGZ=downloads/$(LUA_D).tar.gz
LUA_HOST=host/$(LUA_D)/src/lua

HASERL_D=haserl-$(HASERL_VERSION)
HASERL=$(PREFIX)$(HASERL_D)/src/haserl
HASERL_TGZ=downloads/$(HASERL_D).tar.gz
HASERL_LUA2C=$(PREFIX)$(HASERL_D)/src/lua2c
HASERL_MAKEFILE=$(PREFIX)$(HASERL_D)/Makefile

MONGOOSE_D=mongoose-$(MONGOOSE_VERSION)
MONGOOSE=$(PREFIX)$(MONGOOSE_D)/mongoose
MONGOOSE_TGZ=downloads/$(MONGOOSE_D).tar.gz

SQLITE3_D=sqlite-amalgamation-$(SQLITE3_VERSION)
SQLITE3=$(PREFIX)$(SQLITE3_D)/sqlite3.o
SQLITE3_ZIP=downloads/$(SQLITE3_D).zip

LUASQL_D=luasql-$(LUASQL_VERSION)
LUASQL=$(PREFIX)$(LUASQL_D)/src/sqlite3.so
LUASQL_TGZ=downloads/$(LUASQL_D).tar.gz

LFS_D=luafilesystem-v_$(LFS_VERSION)
LFS=$(PREFIX)$(LFS_D)/src/lfs.so
LFS_TGZ=downloads/$(LFS_D).tar.gz

export LUA_CFLAGS=-I$(PWD)/$(PREFIX)$(LUA_D)/src/
export LUA_LIBS=-L$(PWD)/$(PREFIX)$(LUA_D)/src/ -llua -lm -ldl
export LD_LIBRARY_PATH=$(PWD)/$(PREFIX)$(LUA_D)/src/

all: $(LUA) $(LUA_HOST) $(HASERL) $(MONGOOSE) $(SQLITE3) $(LUASQL) $(LFS) $(PREFIX)bin

all-download: $(LUA_TGZ) $(HASERL_TGZ) $(MONGOOSE_TGZ) $(SQLITE3_ZIP) $(LUASQL_TGZ) $(LFS_TGZ)

$(LUA): $(PREFIX)$(LUA_D)
	@$(MAKE) -C $(PREFIX)$(LUA_D)/src liblua.so LUA_A=liblua.so \
		"AR=$(CC) $(SYSLIBS) -shared -o" RANLIB="$(STRIP)" CC="$(CC)"
	@$(STRIP) $@

$(LUA_HOST):
	@true
ifneq ($(PREFIX),native/)
	@$(MAKE) $(LUA_HD)
	@$(MAKE) -C host/$(LUA_D)/src liblua.a CC="gcc -m32" SYSLIBS="" SYSCFLAGS=""
endif

$(LUA_HD): $(LUA_TGZ)
	@tar xf $< -C host
	@touch $@

$(PREFIX)$(LUA_D): $(LUA_TGZ)
	@tar xf $< -C $(PREFIX)
	@touch $@

$(LUA_TGZ):
	@wget -c http://www.lua.org/ftp/$(LUA_D).tar.gz -O $@.part
	@mv $@.part $@

$(HASERL): $(HASERL_LUA2C) $(HASERL_MAKEFILE)
	@$(MAKE) -C $(PREFIX)$(HASERL_D)
	@$(STRIP) $@

$(HASERL_LUA2C): $(LUA_HOST)
	@true
ifneq ($(PREFIX),native/)
	@$(MAKE) $(PREFIX)$(HASERL_D)
	@gcc -m32 -o $@ $@.c -I $(PWD)/host/$(LUA_D)/src \
		-L $(PWD)/host/$(LUA_D)/src -llua -lm
endif

$(HASERL_MAKEFILE):
	@$(MAKE) $(PREFIX)$(HASERL_D)
	@cd $(PREFIX)$(HASERL_D) && ./configure \
		--host=$(TRIPLE) \
		--enable-subshell=lua \
		--with-lua

$(PREFIX)$(HASERL_D): $(HASERL_TGZ)
	@tar xf $< -C $(PREFIX)
	@touch $@

$(HASERL_TGZ):
	@wget -c http://sourceforge.net/projects/haserl/files/haserl-devel/$(HASERL_D).tar.gz -O $@.part
	@mv $@.part $@

$(MONGOOSE):
	@$(MAKE) $(PREFIX)$(MONGOOSE_D)
	@$(CC) -pthread -O2 -o $@ \
		$(PREFIX)$(MONGOOSE_D)/examples/web_server/web_server.c \
		$(PREFIX)$(MONGOOSE_D)/mongoose.c -I$(PREFIX)$(MONGOOSE_D)
	@$(STRIP) $@

$(PREFIX)$(MONGOOSE_D): $(MONGOOSE_TGZ)
	@tar xf $< -C $(PREFIX)
	@touch $@

$(MONGOOSE_TGZ):
	@wget -c https://github.com/cesanta/mongoose/archive/$(MONGOOSE_VERSION).tar.gz -O $@.part
	@mv $@.part $@

$(SQLITE3):
	@$(MAKE) $(PREFIX)$(SQLITE3_D)
	@cd $(PREFIX)$(SQLITE3_D) && \
		$(CC) -O2 -fPIC -c sqlite3.c

$(PREFIX)$(SQLITE3_D): $(SQLITE3_ZIP)
	@cd $(PREFIX) && unzip ../$<
	@touch $@

$(SQLITE3_ZIP):
	@wget -c http://www.sqlite.org/$(SQLITE3_YEAR)/$(SQLITE3_D).zip -O $@.part
	@mv $@.part $@

$(LUASQL):
	@$(MAKE) $(PREFIX)$(LUASQL_D)
	@cd $(PREFIX)$(LUASQL_D)/src && $(CC) -pthread -O2 -fPIC -shared \
		-o $(PWD)/$@ $(LUA_CFLAGS) $(LUA_LIBS) \
		-I $(PWD)/$(PREFIX)$(SQLITE3_D) \
		$(PWD)/$(PREFIX)$(SQLITE3_D)/sqlite3.o luasql.c ls_sqlite3.c
	@$(STRIP) $@

$(PREFIX)$(LUASQL_D): $(LUASQL_TGZ)
	@tar xf $< -C $(PREFIX)
	@touch $@

$(LUASQL_TGZ):
	@wget -c https://github.com/keplerproject/luasql/archive/v$(LUASQL_VERSION).tar.gz -O $@.part
	@mv $@.part $@

$(LFS):
	@$(MAKE) $(PREFIX)$(LFS_D)
	cd $(PREFIX)$(LFS_D)/src && $(CC) -O2 -fPIC -shared \
		-o $(PWD)/$@ $(LUA_CFLAGS) $(LUA_LIBS) lfs.c
	@$(STRIP) $@

$(PREFIX)$(LFS_D): $(LFS_TGZ)
	@tar xf $< -C $(PREFIX)
	@touch $@

$(LFS_TGZ):
	@wget -c https://github.com/keplerproject/luafilesystem/archive/v_$(LFS_VERSION).tar.gz -O $@.part
	@mv $@.part $@

$(PREFIX)bin:
	@mkdir -p $@/luasql
	@cp $(LUA) $(HASERL) $(MONGOOSE) $(LFS) $@
	@cp $(LUASQL) $@/luasql
ifeq ($(PREFIX),android/)
	@sed s-bin/sh-system/bin/sh- luaw.sh > $@/luaw
else
	@cp luaw.sh $@/luaw
endif
	@chmod +x $@/luaw
	@ln -sf ../../www $@

clean:
	@$(RM) -r android downloads/*.part host native

clean-download: clean
	@$(RM) -r downloads

.PHONY: android all all-download $(PREFIX)bin clean clean-download native
