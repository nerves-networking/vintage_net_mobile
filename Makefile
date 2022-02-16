ifeq ($(MIX_APP_PATH),)
calling_from_make:
	mix compile
else

PREFIX = $(MIX_APP_PATH)/priv

all:
	$(MAKE) -C c_src/ppp_to_elixir
	$(MAKE) -C c_src/pppd_shim
	cp -R c_src/etc $(PREFIX)

clean:
	$(MAKE) -C c_src/ppp_to_elixir clean
	$(MAKE) -C c_src/pppd_shim clean

format:
	$(MAKE) -C c_src/ppp_to_elixir format
	$(MAKE) -C c_src/pppd_shim format
endif

.PHONY: all clean calling_from_make format

# Don't echo commands unless the caller exports "V=1"
${V}.SILENT:
