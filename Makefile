KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build
MODULE_NAME := lattepanda_ec_hwmon

obj-m := $(MODULE_NAME).o

all:
	$(MAKE) -C $(KDIR) M=$(PWD) LLVM=1 modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) LLVM=1 clean

install: all
	$(MAKE) -C $(KDIR) M=$(PWD) LLVM=1 modules_install
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
