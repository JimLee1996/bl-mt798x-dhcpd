# ADR 0001: Use the NMBM MTK U-Boot layout for ZHAO 7981r128

## Status

Accepted

## Context

The ImmortalWrt reference device tree for `zhao,7981r128` uses an MTK U-Boot layout on SPI-NAND with `mediatek,nmbm` enabled. Its partition contract is:

`nmbm0:1024k(bl2),512k(u-boot-env),2048k(factory),2048k(fip),114M(ubi)`

The Linux device tree also exposes an SFP WAN path, but existing MT7981 U-Boot board device trees in this repository do not provide a matching SFP recovery-network pattern.

## Decision

Add `zhao_7981r128` as a default NMBM board and keep the U-Boot failsafe network entry on the LAN/switch side.

Also provide a `multi_layout` U-Boot defconfig so the repository's default `MULTI_LAYOUT=1` flow can build the board without falling back, while keeping only the reference ImmortalWrt layout in the board device tree.

## Consequences

The produced bootloader matches the referenced ImmortalWrt NMBM firmware layout and should not be used with non-NMBM images.

SFP bootloader networking is intentionally deferred until it can be validated with board logs or a known-good MT7981 U-Boot SFP example.
