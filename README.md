# AppSync Unified
###### Unified AppSync dynamic library for iOS 5, 6, 7, and 8.

Copyright (c) 2014 Linus Yang, Karen Tsai (angelXwind)

Disclaimer
----------
* **AppSync Unified** is **NOT** for piracy. 
* **AppSync Unified** is **for freedom of iOS development with the official Xcode iOS SDK.**
* **Jailbreaking** is **NOT** for  piracy. 
* **Jailbreaking** is **for freedom of your iOS device.**

Introduction
------------
AppSync Unified is a tweak that patches installd to allow for the installation of unsigned IPA packages on an iOS device. This is particularly useful for iOS developers who are not enrolled in Apple's official iOS Developer Program, as it allows these developers to debug and test their apps on their own devices using modifications such as iOSOpenDev.

As of now, all other so-called "AppSync for iOS 7" packages are actually mirrors of "PPSync," an incredibly strange installd patch made by the notorious Chinese iOS piracy website, [25pp.com](http://pro.25pp.com).

This 25pp version of AppSync, PPSync, modifies `installd`'s launch daemon plist file for interposing signature checking routines, which is **an ugly workaround** and **extremely unstable**, causing system apps to randomly crash, among other undesirable behaviour.

Even more baffling is how PPSync's `postinst` script symlinks all system applications to `/User/Applications/`, which ... actually causes more problems than what they were trying to solve. No idea what they were trying to do there.

AppSync Unified utilizes the dynamic hooking function `MSHookFunction` of @saurik's Cydia Substrate to bypass the signature check, which does not modify any system files and is much more stable and safe.

Again, AppSync is **NOT** meant to support piracy. Obviously it can still be used in that way, and I, nor anyone else can really stop you if you want to pirate, but **please don't pirate and support the developers!**

Reference
---------
[com.saurik.iphone.fmil by @saurik](http://svn.saurik.com/repos/menes/trunk/tweaks/fmil/Tweak.mm)

Compiling AppSync Unified
-------------------------
```
git clone https://github.com/angelXwind/AppSync.git
cd AppSync
make
make package #requires dpkg, install using Homebrew - http://brew.sh/
```

Cydia Repository
----------------

Karen's Pineapple Repo: http://cydia.angelxwind.net/

AppSync Unified Depiction page: http://cydia.angelxwind.net/?page/net.angelxwind.appsyncunified

Please don't steal AppSync Unified and take credit for it. You just end up looking like an idiot when you do that.

License
-------
Licensed under [GPLv3](http://www.gnu.org/copyleft/gpl.html).
