
LUA_VERSION=5.2.3
HASERL_VERSION=0.9.33
MONGOOSE_VERSION=5.5
SQLITE3_VERSION=3080802

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

MONGOOSE_D=mongoose-$(MONGOOSE_VERSION)
MONGOOSE=$(MONGOOSE_D)/mongoose
MONGOOSE_TGZ=downloads/$(MONGOOSE_D).tar.gz

SQLITE3_D=sqlite-amalgamation-$(SQLITE3_VERSION)
SQLITE3=$(SQLITE3_D)/sqlite3.o
SQLITE3_ZIP=downloads/$(SQLITE3_D).zip

export LUA_CFLAGS=-I$(PWD)/$(LUA_D)/src/
export LUA_LIBS=-L$(PWD)/$(LUA_D)/src/ -llua -lm

all: $(LUA) $(LUA_HOST) $(HASERL) $(MONGOOSE) $(SQLITE3)

all-download: $(LUA_TGZ) $(HASERL_TGZ) $(MONGOOSE_TGZ) $(SQLITE3_ZIP)

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

$(MONGOOSE):
	@$(MAKE) $(MONGOOSE_D)
	@$(CC) -O2 -o $@ \
		$(MONGOOSE_D)/examples/web_server/web_server.c \
		$(MONGOOSE_D)/mongoose.c -I$(MONGOOSE_D)
	@$(STRIP) $@

$(MONGOOSE_D): $(MONGOOSE_TGZ)
	@tar xf $<
	@touch $@

$(MONGOOSE_TGZ):
	@mkdir -p downloads
	@wget -c https://github.com/cesanta/mongoose/archive/$(MONGOOSE_VERSION).tar.gz -O $@.part
	@mv $@.part $@

$(SQLITE3):
	@$(MAKE) $(SQLITE3_D)
	@cd $(SQLITE3_D) && $(CC) -O2 -c sqlite3.c

$(SQLITE3_D): $(SQLITE3_ZIP)
	@unzip $<
	@touch $@

$(SQLITE3_ZIP):
	@mkdir -p downloads
	@wget -c http://www.sqlite.org/2015/$(SQLITE3_D).zip -O $@.part
	@mv $@.part $@

clean:
	@$(RM) -r $(LUA_D) $(LUA_HD) $(HASERL_D) $(MONGOOSE_D) $(SQLITE3_D)

clean-downloads: clean
	@$(RM) -r downloads
