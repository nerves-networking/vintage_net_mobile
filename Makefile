ifeq ($(MIX_APP_PATH),)
calling_from_make:
	mix compile
else

PREFIX = $(MIX_APP_PATH)/priv

all:
	$(MAKE) -C src/ppp_to_elixir
	$(MAKE) -C src/pppd_shim
	cp -R src/etc $(PREFIX)

clean:
	$(MAKE) -C src/ppp_to_elixir clean
	$(MAKE) -C src/pppd_shim clean

format:
	$(MAKE) -C src/ppp_to_elixir format
	$(MAKE) -C src/pppd_shim format
endif

.PHONY: all clean calling_from_make format

