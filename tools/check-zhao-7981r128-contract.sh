#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
wrt_root="$(cd "$repo_root/.." && pwd)"

configs=(
	"$repo_root/uboot-mtk-20250711/configs/mt7981_zhao_7981r128_defconfig"
	"$repo_root/uboot-mtk-20250711/configs/mt7981_zhao_7981r128_multi_layout_defconfig"
)

uboot_dts="$repo_root/uboot-mtk-20250711/arch/arm/dts/mt7981-zhao-7981r128.dts"
openwrt_image="$wrt_root/immortalwrt-mt798x-rebase/target/linux/mediatek/image/filogic-ext.mk"

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

for cfg in "${configs[@]}"; do
	[ -f "$cfg" ] || fail "missing $cfg"

	grep -q '^CONFIG_DEFAULT_DEVICE_TREE="mt7981-zhao-7981r128"$' "$cfg" ||
		fail "$(basename "$cfg") does not select the zhao device tree"
	grep -q '^CONFIG_ENABLE_NAND_NMBM=y$' "$cfg" ||
		fail "$(basename "$cfg") does not enable NMBM"
	grep -q '^CONFIG_MTK_UBI_SUPPORT=y$' "$cfg" ||
		fail "$(basename "$cfg") does not enable UBI support"
	grep -q '^CONFIG_MTK_UPGRADE_IMAGE_VERIFY=y$' "$cfg" ||
		fail "$(basename "$cfg") does not verify firmware before upgrade"
	grep -q '^CONFIG_MTD_VERIFY_FDT=y$' "$cfg" ||
		fail "$(basename "$cfg") does not verify Linux FDT before boot"
	grep -q '^# CONFIG_MTD_VERIFY_FDT_WARN_ONLY is not set$' "$cfg" ||
		fail "$(basename "$cfg") allows FDT verification failures to continue booting"
	! grep -q '^CONFIG_MTK_DEFAULT_FIT_BOOT_CONF=' "$cfg" ||
		fail "$(basename "$cfg") forces FIT volume boot and may hide sysupgrade tar output"
done

[ -f "$uboot_dts" ] || fail "missing $uboot_dts"

grep -q 'mtdids = "nmbm0=nmbm0";' "$uboot_dts" ||
	fail "zhao U-Boot DTS does not select the NMBM MTD device"
grep -q '114688k(ubi)' "$uboot_dts" ||
	fail "zhao U-Boot DTS does not match the 114688k zhao UBI partition"

grep -q '114688k(ubi)' "${configs[0]}" ||
	fail "$(basename "${configs[0]}") does not match the 114688k zhao UBI partition"
if grep -q '^CONFIG_MEDIATEK_MULTI_MTD_LAYOUT=y$' "${configs[1]}"; then
	! grep -q '^CONFIG_MTDPARTS_DEFAULT=' "${configs[1]}" ||
		fail "$(basename "${configs[1]}") should use DTS mtd-layout instead of static MTDPARTS_DEFAULT"
else
	grep -q '114688k(ubi)' "${configs[1]}" ||
		fail "$(basename "${configs[1]}") does not match the 114688k zhao UBI partition"
fi

[ -f "$openwrt_image" ] || fail "missing OpenWrt image definition"

awk '
	/^define Device\/zhao_7981r128-mtkuboot$/ { in_device = 1 }
	in_device { block = block $0 "\n" }
	in_device && /^endef$/ { print block; found = 1; exit }
	END { if (!found) exit 1 }
' "$openwrt_image" > /tmp/zhao-7981r128-openwrt-image.block ||
	fail "missing zhao_7981r128-mtkuboot image definition"

grep -q 'KERNEL_IN_UBI := 1' /tmp/zhao-7981r128-openwrt-image.block ||
	fail "OpenWrt reference target no longer keeps kernel in UBI"
grep -q 'IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata' /tmp/zhao-7981r128-openwrt-image.block ||
	fail "OpenWrt reference target no longer produces sysupgrade tar"
grep -q 'IMAGE/factory.bin := append-ubi' /tmp/zhao-7981r128-openwrt-image.block ||
	fail "OpenWrt reference target no longer produces append-ubi factory image"

printf 'OK: zhao 7981r128 U-Boot/OpenWrt flash contract matches expected NMBM + UBI sysupgrade tar layout.\n'
