# lattepanda-sigma-ec-hwmon

Linux hardware monitoring (hwmon) kernel driver for the **LattePanda Sigma** single-board computer.

**Maintainer**: Mariano Abad <weimaraner@gmail.com>

## Overview

The LattePanda Sigma uses an ITE IT8613E Embedded Controller (EC) running 8051 firmware to manage fan speed, temperatures and power. However, the BIOS declares the ACPI EC as disabled (`_STA=0`), so Linux never sees these sensors through standard interfaces — `lm-sensors` shows nothing for the fan or board temperatures out of the box.

This driver bypasses that limitation by reading the EC registers directly via ACPI EC I/O ports (`0x62`/`0x66`) and exposes fan RPM, board temperature, and CPU temperature through the standard Linux hwmon sysfs interface, making them visible to `lm-sensors`, Grafana, `conky`, and any monitoring tool.

The EC register map was reverse-engineered from the firmware binary. Fan speed is controlled autonomously by the EC and is not writable from the host — see [EC Register Discovery](#ec-register-discovery) for details.

The driver uses **DMI matching** and only loads on verified LattePanda Sigma hardware — it is safe to install on any machine.

## Sensors

| Attribute | Type | EC Register | Description |
|-----------|------|-------------|-------------|
| `fan1_input` | RPM | `0x2E:0x2F` | CPU fan speed (16-bit big-endian) |
| `fan1_label` | string | — | "CPU Fan" |
| `temp1_input` | m°C | `0x60` | Board/ambient temperature |
| `temp1_label` | string | — | "Board Temp" |
| `temp2_input` | m°C | `0x70` | CPU proximity temperature |
| `temp2_label` | string | — | "CPU Temp" |

## Example Output

```
$ sensors lattepanda_sigma_ec-isa-0000
lattepanda_sigma_ec-isa-0000
Adapter: ISA adapter
CPU Fan:     2900 RPM
Board Temp:   +45.0°C
CPU Temp:     +69.0°C
```

## Quick Start

```bash
# Build (requires clang + lld if your kernel was built with LLVM)
make

# Load
sudo insmod lattepanda_sigma_ec_hwmon.ko

# Verify
sensors

# Unload
sudo rmmod lattepanda_sigma_ec_hwmon
```

## Installation

### Manual

```bash
sudo make install
sudo depmod -a
echo "lattepanda_sigma_ec_hwmon" | sudo tee /etc/modules-load.d/lattepanda-sigma-ec-hwmon.conf
```

### DKMS (auto-rebuild on kernel updates)

```bash
sudo cp -r . /usr/src/lattepanda-sigma-ec-hwmon-1.0.0
sudo dkms add lattepanda-sigma-ec-hwmon/1.0.0
sudo dkms build lattepanda-sigma-ec-hwmon/1.0.0
sudo dkms install lattepanda-sigma-ec-hwmon/1.0.0
```

## Upstream Submission

This driver is structured to be submittable to the Linux kernel hwmon subsystem. The repository includes:

| File | Purpose |
|------|---------|
| `lattepanda_sigma_ec_hwmon.c` | Driver source (passes `checkpatch.pl --strict`) |
| `doc/lattepanda-sigma-ec.rst` | Kernel `Documentation/hwmon/` entry |
| `Kconfig.entry` | Fragment for `drivers/hwmon/Kconfig` |
| `MAINTAINERS.entry` | Fragment for `MAINTAINERS` |

To submit upstream, the driver would be sent as a patch series to `linux-hwmon@vger.kernel.org` using `git format-patch` and `git send-email`.

## EC Register Discovery

The EC register map was discovered empirically by:

1. Dumping all 256 EC registers via I/O ports `0x62`/`0x66`
2. Taking multiple snapshots to identify registers that change in real-time
3. Physically stopping the fan and confirming RPM drop to 0

See [`doc/lattepanda-sigma-ec.rst`](doc/lattepanda-sigma-ec.rst) for full details.

## Hardware

- **Board**: LattePanda Sigma
- **CPU**: Intel 13th Gen i5-1340P
- **BIOS**: 5.27
- **EC interface**: ACPI EC ports `0x62` (data) / `0x66` (cmd/status)

## Author

- **Mariano Abad** — [weimaraner@gmail.com](mailto:weimaraner@gmail.com)

## Contributing

Bug reports, testing on other LattePanda models, and patches are welcome. If you have a LattePanda with a different BIOS version, please open an issue with your `dmidecode` output and EC register dump.

## License

GPL-2.0-or-later
