# AppSync Unified
###### Unified AppSync dynamic library for iOS 5 and above.

What is AppSync Unified?
------------------------
AppSync Unified is a tweak that patches installd to allow for the installation of fakesigned IPA packages on an iOS device.

AppSync Unified can be used to downgrade or clone installed apps, to download fakesigned IPAs (often emulators), and also to assist in the development of iOS applications using Xcode 6 or below.

**AppSync Unified should not be used to pirate iOS apps. Please support iOS developers and do not pirate!**

**I explain the problem with AppSync Unified and iOS piracy rather thoroughly [in this reddit post](https://www.reddit.com/r/jailbreak/comments/3oovnh/discussion_regarding_appsync_unified_ios_9_and/). Please give it a read.**

Official Cydia Repository
-------------------------
You can find AppSync Unified at **Karen's Pineapple Repo: https://cydia.angelxwind.net/** ([depiction page](https://cydia.angelxwind.net/?page/net.angelxwind.appsyncunified))

If you do not see AppSync Unified in Karen's Pineapple Repo, then that just means you have another repository added that is also hosting an identical copy of AppSync Unified.

How does it work?
-----------------
AppSync Unified utilizes the dynamic hooking function `MSHookFunction()` in Cydia Substrate to bypass installd's signature checks. This means AppSync Unified **does not modify any system files and is much more stable and safe as a result.**

Can't this be used to pirate apps?
----------------------------------
Unfortunately, yes.

I explain the problem with AppSync Unified and iOS piracy rather thoroughly [in this reddit post](https://www.reddit.com/r/jailbreak/comments/3oovnh/discussion_regarding_appsync_unified_ios_9_and/). Please give it a read.

**tl;dr: AppSync Unified should not be used to pirate iOS apps. Please support iOS developers and do not pirate!**

What makes this better than the other "AppSync"-esque packages?
---------------------------------------------------------------
Many other "AppSync"-esque packages found on various piracy-centered repos are actually all mirrors/repacks of "PPSync," an... incredibly *strange* `installd` patch made by the notorious Chinese iOS piracy website, 25pp.

25pp's version of AppSync, "PPSync," modifies `installd`'s launch daemon plist file to interpose its signature checking routines, which is **an ugly workaround** and **extremely unstable**, causing system apps to randomly crash, among other undesirable behaviour.

Even more baffling is how PPSync's `postinst` creates symbolic links of all system applications to `/User/Applications/`, which causes a multitude of problems.

**tl;dr: AppSync Unified is much more stable than anything else you'll find out there.**

How do I compile AppSync Unified?
---------------------------------
```
git clone https://github.com/angelXwind/AppSync.git
cd AppSync
make
make package #requires dpkg, install using Homebrew - see http://brew.sh/
```

How do I use Xcode 6 (or below) to push my developed apps to my device?
-----------------------------------------------------------------------
Read this: [Tutorial: How to use AppSync Unified for development with Xcode 6 or below](https://angelxwind.net/?page/how2asu)

License
-------
Licensed under [GPLv3](http://www.gnu.org/copyleft/gpl.html).