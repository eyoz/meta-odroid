# Amlogic Meson Soc family

require conf/machine/include/soc-family.inc

SERIAL_CONSOLES ?= "115200;ttyAML0"
UBOOT_CONSOLE ?= "console=ttyAML0,115200"

MACHINE_FEATURES = "alsa screen"
