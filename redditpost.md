### Repo URL: https://cydia.akemi.ai/ ([Tap here on your device to automatically add the repo!](https://cydia.akemi.ai/add.php))

#### Support me with [Patreon](https://patreon.com/akemin_dayo), [PayPal (`karen@akemi.ai`)](https://paypal.me/akemindayo), or [Cryptocurrency](https://akemi.ai/?page/links#crypto)

(A full list of all available donation methods can be found [here](https://akemi.ai/?page/links#donate).)

Any support is _greatly_ appreciated, but donations are *not* and will *never* be necessary to use my software!

---

# Changelog for 114.0 ([full changelog](https://cydia.akemi.ai/?page/ai.akemi.appsyncunified-changelog))

* Added support for all iOS versions up to iOS 16.7.
* AppSync Unified now requires ElleKit 1.1 or newer to be installed on "rootless" mode jailbreaks, as earlier versions are incompatible with AppSync Unified (and perhaps other tweaks) due to a bug. For more information, please see [GitHub issue #174](https://github.com/akemin-dayo/AppSync/issues/174). **Thanks to Évelyne for her hard work in fixing ElleKit!**
* No actual changes were made to AppSync Unified in order to achieve this, but AppSync Unified will now work with all known "rootless" mode jailbreaks as long as the requisite version of ElleKit is installed.

---

# Unified AppSync dynamic library for iOS 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, and 16. Open-source on [GitHub](https://github.com/akemin-dayo/AppSync)!

AppSync Unified is a tweak that allows users to freely install ad-hoc signed, fakesigned, or unsigned IPA app packages on their iOS devices that iOS would otherwise consider invalid.

Some popular use cases include:

* Installing freely-distributed apps that are unavailable from the App Store without having to re-sign the apps in question every 7 days (if the user does not have a subscription to the Apple Developer Program)
* Assisting in the development of iOS applications with Xcode
* Cloning or downgrading already-installed apps

---

# Help! I installed AppSync Unified, but it doesn't seem to be working after I resprung from Cydia/Zebra/Sileo/etc.!

If AppSync Unified is not working after installation, please reboot your device or perform a userspace reboot (`launchctl reboot userspace`, `ldrestart`, etc.) to activate it. You will only need to do this ONCE.

This issue appears to be caused by what …seems like a Cydia Substrate/Substitute bug(?) that's resurfaced from years ago, and occurs _really_ rarely, so it's an absolute nightmare of a bug. It's especially frustrating for me since I'm such a perfectionist when it comes to software development, too ww (🍍˃̶͈̀ロ˂̶͈́)੭ꠥ⁾⁾

**For the curious developers among you:** AppSync Unified's `postinst` binary (see [pkg-actions.m](https://github.com/akemin-dayo/AppSync/blob/master/pkg-actions/pkg-actions.m)) restarts `installd` via `launchctl` — for some reason though, it seems like Cydia Substrate and/or Substitute doesn't always inject the dylib properly into `installd` when it is reloaded via `launchctl` in this way.

I tried _really_ hard to determine the cause of this, but I really have no idea what could be causing this. The dylib has _long_ since been written to the filesystem by the time `postinst` was _executed_, let alone when `launchctl` was even called by `posix_spawn`.

I guess for now, all I can do is inform people about the bug and how to resolve it. ⊂⌒~⊃｡Д｡🍍)⊃

Hopefully I'll be able to properly resolve this in time.

---

# Regarding piracy…

**Please do NOT use AppSync Unified for piracy.**

AppSync Unified is a development tool designed for app developers first and foremost, alongside other valid legal uses that I support — a few of which are outlined above.

**Software piracy is illegal.** Please support the developers of the iOS software you use, whether they be app developers on the App Store or tweak developers on Chariz/Dynastic/etc.

They're just trying to make a living too, much like you and I.