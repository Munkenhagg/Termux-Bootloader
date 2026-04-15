# Termux-Bootloader

##### **Functionality on different linux distros may vary**

## Introduction

- Termux-Bootloader is a login manager originally created for the use of [Termux](https://github.com/termux/termux-app)

- Despite the original name, this is **not** an actual bootloader and does not modify your actual system

## Core features

- **User management:** This script can **add** and **remove** users stored in a JSON file

- **Permissions:** you are restricted from doing different managing and other stuff if you do not have the *owner* **Permission**

- **Configuration Wizard:** there is a configuration script to help you configure the [Config JSON](https://github.com/Munkenhagg/Termux-Bootloader/blob/main/EXAMPLE.json)

- **Per-User Salt:** Every user is generated a [Salt](https://en.wikipedia.org/wiki/Salt_(cryptography)) for extra security ontop of sha256

## Installation

[![Static Badge](https://img.shields.io/badge/Download-Zip-brightgreen)](https://github.com/Munkenhagg/Termux-Bootloader/archive/refs/heads/main.zip)

After downloading the zip, if you want the script to always run when starting termux, run `echo "bash $HOME/Termux-Bootloader-main/bootloader.sh" >> /data/data/com.termux/files/usr/etc/termux-login.sh`

## System requirements

- **RAM:** RAM needed for the whole environment the script requires(bash, jq, etc)

##### Minimum: 15MB

##### Recommended: 60MB

- **CPU Minimum:** the recommended minimum cpu needed for the script

##### ARMv7: Cortex-A8

##### ARMv8: Cortex-A55

##### X86: Pentium III

- **Storage:** the storage needed for this script(excluding termux and tools)

##### Minimum: MicroSD, 30kb free

##### Recommended: eMMC, 4MB free
