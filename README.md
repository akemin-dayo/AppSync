# AppSync Unified
###### Unified AppSync dynamic library for iOS 5, 6, 7, 8, 9, 10, 11, and 12.

What is AppSync Unified?
------------------------
AppSync Unified is a tweak that patches `installd` to allow for the installation of unsigned, fakesigned, or ad-hoc signed IPA packages on an iOS device.

AppSync Unified can be used to downgrade or clone installed apps, to download fakesigned IPAs (often emulators), and also to assist in the development of iOS applications using Xcode.

**AppSync Unified should not be used to pirate iOS apps. Please support iOS app developers and do not pirate!**

**I explain the problem with AppSync Unified and iOS piracy rather thoroughly [in this reddit post](https://www.reddit.com/r/jailbreak/comments/3oovnh/discussion_regarding_appsync_unified_ios_9_and/). Please give it a read.**

Official Cydia Repository
-------------------------
You can find AppSync Unified at **Karen's Repo: https://cydia.akemi.ai/** ([depiction page](https://cydia.akemi.ai/?page/net.angelxwind.appsyncunified))

If you do not see AppSync Unified in Karen's Repo, then that just means you have another repository added that is also hosting an identical copy of AppSync Unified. Please only use the official unmodified release for your own safety — third-party modifications can and _have_ caused damage to iOS installations.

How does it work?
-----------------
AppSync Unified utilizes the dynamic hooking function `MSHookFunction()` in Cydia Substrate to bypass installd's signature checks. This means AppSync Unified **does not modify any system files and is much more stable and safe as a result.**

Can't this be used to pirate apps?
----------------------------------
Unfortunately, yes.

I explain the problem with AppSync Unified and iOS piracy rather thoroughly [in this reddit post](https://www.reddit.com/r/jailbreak/comments/3oovnh/discussion_regarding_appsync_unified_ios_9_and/). Please give it a read.

**tl;dr: AppSync Unified should not be used to pirate iOS apps. Please support iOS developers and do not pirate!**

How do I compile AppSync Unified?
---------------------------------
```
git clone https://github.com/angelXwind/AppSync.git
cd AppSync
make
make package #requires dpkg, install using Homebrew - see http://brew.sh/
```

How do I use this with Xcode to push my developed apps to my device?
--------------------------------------------------------------------
For Xcode 7 and above, simply use your device with Xcode as you would normally.

For Xcode 6 and below, please follow this tutorial: [Tutorial: How to use AppSync Unified for development with Xcode 6 or below](https://akemi.ai/?page/how2asu)

License
-------
Licensed under [GPLv3](http://www.gnu.org/copyleft/gpl.html).