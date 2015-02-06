
android:
	@mkdir -p host downloads $@
	@$(MAKE) all PREFIX=$@/ \
		CC=arm-linux-androideabi-gcc \
		STRIP=arm-linux-androideabi-strip

LUA_VERSION=5.2.3
HASERL_VERSION=0.9.33
MONGOOSE_VERSION=5.5
SQLITE3_VERSION=3080802

LUA_D=lua-$(LUA_VERSION)
LUA=$(PREFIX)$(LUA_D)/src/lua
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

export LUA_CFLAGS=-I$(PWD)/$(PREFIX)$(LUA_D)/src/
export LUA_LIBS=-L$(PWD)/$(PREFIX)$(LUA_D)/src/ -llua -lm

all: $(LUA) $(LUA_HOST) $(HASERL) $(MONGOOSE) $(SQLITE3)

all-download: $(LUA_TGZ) $(HASERL_TGZ) $(MONGOOSE_TGZ) $(SQLITE3_ZIP)

$(LUA): $(PREFIX)$(LUA_D)
	@$(MAKE) -C $(PREFIX)$(LUA_D)/src liblua52.so LUA_A=liblua52.so \
		"AR=$(CC) -Wl,-E -shared -o" RANLIB="$(STRIP)" CC="$(CC)" \
		MYCFLAGS="'-Dgetlocaledecpoint()=46'"
	@$(MAKE) -C $(PREFIX)$(LUA_D)/src all CC="$(CC)" \
		MYCFLAGS="'-Dgetlocaledecpoint()=46' \
		-DLUA_USE_POSIX -DLUA_USEDLOPEN" MYLIBS="-Wl,-E -ldl" MYLDFLAGS=-s
	@$(STRIP) $@

$(LUA_HOST): $(LUA_HD)
	@$(MAKE) -C host/$(LUA_D)/src liblua.a CC=gcc

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
	@$(MAKE) $(PREFIX)$(HASERL_D)
	@gcc -o $@ $@.c -I $(PWD)/host/$(LUA_D)/src \
		-L $(PWD)/host/$(LUA_D)/src -llua -lm

$(HASERL_MAKEFILE):
	@$(MAKE) $(PREFIX)$(HASERL_D)
	@cd $(PREFIX)$(HASERL_D) && ./configure \
		--prefix=/usr \
		--host=arm-linux-androideabi \
		--with-lua=lua5.2

$(PREFIX)$(HASERL_D): $(HASERL_TGZ)
	@tar xf $< -C $(PREFIX)
	@touch $@

$(HASERL_TGZ):
	@wget -c http://sourceforge.net/projects/haserl/files/haserl-devel/$(HASERL_D).tar.gz -O $@.part
	@mv $@.part $@

$(MONGOOSE):
	@$(MAKE) $(PREFIX)$(MONGOOSE_D)
	@$(CC) -O2 -o $@ \
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
	@cd $(PREFIX)$(SQLITE3_D) && $(CC) -O2 -c sqlite3.c

$(PREFIX)$(SQLITE3_D): $(SQLITE3_ZIP)
	@cd $(PREFIX) && unzip ../$<
	@touch $@

$(SQLITE3_ZIP):
	@wget -c http://www.sqlite.org/2015/$(SQLITE3_D).zip -O $@.part
	@mv $@.part $@

clean:
	@$(RM) -r host android

clean-downloads: clean
	@$(RM) -r downloads

.PHONY: android
