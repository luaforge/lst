
#
# This makefile assumes you are using a local LPeg and not one
# installed in your system Lua install.
#
LPEG_MODULE = ../lpeg/lpeg.so
LPEG_DIR = $(dir $(LPEG_MODULE))

.PHONY: all
all: $(LPEG_MODULE)

.PHONY: check
check: all 
	@src/tests/lunit \
	  --path "src/?.lua;src/tests/?.lua;;;" \
	  --cpath "$(LPEG_DIR)/?.so;;" $(LUNIT_ARGS) \
	  src/tests/Suite.lua

$(LPEG_MODULE):
	$(MAKE) -C $(LPEG_DIR) 


