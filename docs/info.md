<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

An SPI-controlled PWM peripheral. An SPI controller writes to five registers
(output enables, PWM enables, and a duty cycle), and the PWM module drives
16 outputs based on those registers.

## How to test

Run `make -B` in the `test` folder.

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
