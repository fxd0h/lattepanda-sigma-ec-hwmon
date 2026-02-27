Kernel driver lattepanda-ec
===========================

Supported systems:

  * LattePanda Sigma (Intel 13th Gen i5-1340P)

    DMI vendor: LattePanda

    DMI product: LattePanda Sigma

    Datasheet: Not available (EC registers discovered empirically)

Author: Mariano Abad <weimaraner@gmail.com>

Description
-----------

This driver provides hardware monitoring for the LattePanda Sigma
single-board computer. The board's Embedded Controller manages a CPU
cooling fan but does not expose fan speed through standard ACPI hwmon
interfaces (no ``PNP0C09`` EC device, no ``fan*_input`` in hwmon).

This driver reads the EC registers directly via the standard ACPI EC
I/O ports (``0x62`` data, ``0x66`` command/status) using the EC read
command ``0x80``.

The EC register map was discovered empirically by dumping all 256
registers and identifying those that change in real-time, then
validating by physically stopping the fan and observing the RPM drop
to zero.

The driver uses DMI matching and will only load on LattePanda Sigma
hardware.

Sysfs attributes
----------------

======================= ===============================================
``fan1_input``          Fan speed in RPM (EC registers 0x2E:0x2F,
                        16-bit big-endian)
``fan1_label``          "CPU Fan"
``temp1_input``         Board/ambient temperature in millidegrees
                        Celsius (EC register 0x60)
``temp1_label``         "Board Temp"
``temp2_input``         CPU proximity temperature in millidegrees
                        Celsius (EC register 0x70)
``temp2_label``         "CPU Temp"
``pwm1``               Fan duty cycle, 0-255 (mapped from EC register
                        0x93 which stores 0-100%)
``pwm1_enable``         Fan control mode (read-only, always returns 2
                        for automatic EC control)
======================= ===============================================

Known limitations
-----------------

* The EC register map was reverse-engineered on a LattePanda Sigma with
  BIOS version 5.27. Different BIOS versions may use different register
  offsets.
* Fan speed control (writing to ``pwm1``) is not supported. The fan is
  always under EC automatic control.
* The I/O ports ``0x62``/``0x66`` may be shared with other ACPI EC users.
  The driver uses ``devm_request_region()`` but continues if the ports
  are already reserved.
