KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build
MODULE_NAME := lattepanda_sigma_ec_hwmon

# Auto-detect LLVM: use LLVM=1 if the kernel was built with clang
LLVM ?= $(shell grep -s '^CONFIG_CC_IS_CLANG=y' $(KDIR)/.config > /dev/null 2>&1 && echo 1)

obj-m := $(MODULE_NAME).o

all:
	$(MAKE) -C $(KDIR) M=$(PWD) $(if $(LLVM),LLVM=$(LLVM)) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) $(if $(LLVM),LLVM=$(LLVM)) clean

install: all
	$(MAKE) -C $(KDIR) M=$(PWD) $(if $(LLVM),LLVM=$(LLVM)) modules_install
	depmod -a $(KVER)

load: all
	-sudo rmmod $(MODULE_NAME) 2>/dev/null
	sudo insmod $(MODULE_NAME).ko
	@echo "--- dmesg ---"
	@dmesg | tail -5
	@echo "--- sensors ---"
	@sensors $(MODULE_NAME)-* 2>/dev/null || echo "(sensors not showing yet, try: sensors)"

unload:
	sudo rmmod $(MODULE_NAME)

.PHONY: all clean install load unload
