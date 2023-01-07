## FreeBSD on StarFive VisionFive 2

I'm working on getting FreeBSD running nicely on the [StarFive VisionFive 2](https://www.kickstarter.com/projects/starfive/visionfive-2), a nice RISC-V board recently released. I'll be dropping scripts, notes, programs and anything else relevant in this repo until I get beyond early experiments.

Latest progress (2023-01-07): first boot completes! No drivers for anything yet.

### Getting started

Get your board running on the provided Linux image first. This makes sure your board actually works, and you can flash an SD card.

Make sure you set up the serial port according to the docs. FreeBSD has no driver support for anything on this board yet, so the serial console will be your only window to the world.

### Create an image

Run `mkvf2img.sh`. This will produce `vf2.img`, a complete FreeBSD 13.1 base image with everything needed to boot on the VF2 and run from memory (necessary, since we have no device drivers yet). Flash it to an SD card.

### Boot the FreeBSD loader

Insert the SD card, and power up. On the serial console, when it gets to `Hit any key to stop autoboot:`, hit a key to get to the `StarFive #` prompt. Then enter the following commands to setup and boot the FreeBSD loader:

```
fatload mmc 1:1 0x48000000 dtb/starfive/jh7110-visionfive-v2.dtb
fatload mmc 1:1 0x44000000 efi/boot/bootriscv64.efi
bootefi 0x44000000 0x48000000
```

### Load the root filesystem and boot the system

When you see the `Hit [Enter] to boot immediately, or any other key for command prompt`, hit a key to get to the `OK` prompt. The enter the following commands to load the root filesystem and boot the system:

```
load geom_uzip
load -t md_image /root.img.uzip
boot
```

(`root.img.uzip` is large, and will take a while to load).

At the `mountroot>` prompt:

```
ufs:/dev/md0.uzip
```

Watch the kernel messages fly by, until finally:

```
FreeBSD/riscv (generic) (rcons)

login: 
```

Login with username `root`, password `root`. Enjoy!
