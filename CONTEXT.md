# Context

## Glossary

### Bootloader layout

The storage contract shared by BL2, FIP/U-Boot, and the operating system image. A board build is only valid when its bootloader layout matches the firmware layout it will boot.

### NMBM layout

A bootloader layout where SPI-NAND partitions are addressed through the `nmbm0` device. It must not be mixed with a non-NMBM firmware layout.

### Failsafe network entry

The Ethernet path expected to provide recovery access while U-Boot is running in failsafe mode. It does not need to expose every network interface that Linux supports.
