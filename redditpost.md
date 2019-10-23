### Repo URL: https://cydia.akemi.ai/ (You can [tap here to add!](https://cydia.akemi.ai/add.php))

#### Support me with [Patreon](https://patreon.com/akemin_dayo), [PayPal (`rei@akemi.ai`)](https://paypal.me/angelXwind), or [Cryptocurrency](https://akemi.ai/?page/links#crypto)

Any support is _greatly_ appreciated, but donations are *not* and will *never* will be necessary to use my software! 

---

# Changelog for 48.0-NoChimera ([full changelog](https://cydia.akemi.ai/?page/net.angelxwind.appsyncunified-changelog))

* Finally added compatibility with A12 (arm64e) devices running the unc0ver jailbreak! (Chimera is NOT supported at this time due to technical restraints.)

---

# Wait, why is there no Chimera support…?

First, I just want to preface this with the following disclaimer: **This is _not_ an attack on Chimera or CoolStar.**

The reason why AppSync Unified 48.0 does not yet work with the Chimera jailbreak is due to Chimera shipping a _broken_ version of Substitute that breaks many different tweaks, including TetherMe, Safari Downloader Plus, and… well, AppSync Unified.

unc0ver has already patched the bug as of version v3.7.0~b3, released about a week ago as of this writing. (For more technical information, see sbingner's Substitute fork, [commit SHA-1 070147453f2038b656b4ebef775d21995220f4bf](https://github.com/sbingner/substitute/commit/070147453f2038b656b4ebef775d21995220f4bf))

Basically, the issue all along for all these months actually had _nothing_ to do with my code for AppSync Unified, but with Substitute, the code injection framework itself. (… So basically, I spent multiple months tearing my hair out for nothing haaaaaaaaaaaaaaaaaa…)

Once Chimera pushes an update that fixes this bug on their fork of Substitute, I will release an update to AppSync Unified that will allow installation for those using the Chimera jailbreak.

Thank you for reading, and I truly apologise for the long, _long_ delay it has taken for me to push this update.

Expect more updates to my other tweaks in the coming days.

---

# Unified AppSync dynamic library for iOS 5, 6, 7, 8, 9, 10, 11, and 12.

* AppSync Unified is **NOT** for piracy.

* AppSync Unified is for **freedom of iOS development with the official Xcode iOS SDK.**

* Jailbreaking is **NOT** for piracy.

* Jailbreaking is for **freedom of your iOS device.**

AppSync Unified is a tweak that patches `installd` to allow for the installation of unsigned, fakesigned, or ad-hoc signed IPA packages on an iOS device.

AppSync Unified can be used to downgrade or clone installed apps, to download fakesigned IPAs (often emulators), and also to assist in the development of iOS applications using Xcode.

**AppSync Unified should not be used to pirate iOS apps. Please support iOS app developers and do not pirate!**

**I explain the problem with AppSync Unified and iOS piracy rather thoroughly [in this reddit post](https://www.reddit.com/r/jailbreak/comments/3oovnh/discussion_regarding_appsync_unified_ios_9_and/). Please give it a read.**