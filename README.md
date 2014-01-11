# AppSync for iOS 7 
_iOS 5+ is supported_

v0.1 by Linus Yang

## Things you need to know first
* __AppSync__ is __NOT__ for piracy. 
* __AppSync__ is __for__ _freedom of iOS development with official SDK_.
* __Jailbreak__ is __NOT__ for  piracy. 
* __Jailbreak__ is __for__ _freedom of your iOS device_.
* __NO__ Debian package of AppSync will be provided here.

Introduction
------
_AppSync_ is a tool to synchronize your IPA Package freely, especially useful for iOS developers who are not enrolled in the iOS developers' program to test their apps on devices.

Currently, all so-called "AppSync for iOS 7" is made by the notorious Chinese iOS piracy website pp25.com. This pp25 version of AppSync modifies `installd`'s launch daemon plist file for interposing signature checking routines, which is __an ugly workaround__ and __extremely unstable__, causing force close of system apps, or other unexpected behaviours.

On the contrary, the AppSync implementation here ultilizes the dynamic hooking function `MSHookFunction` of Cydia Substrate by @saurik to bypass the signature check, which does not modify any system files and is more generic, stable and safe.

Again, AppSync is __NOT__ meant to support privacy. __Please no piracy and support developers!__

Build
------
    git clone --recursive https://github.com/linusyang/AppSync.git
    cd AppSync
    make
    make package # If you have dpkg-deb utilities
