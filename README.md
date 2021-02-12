# AppSync Unified
###### Unified AppSync dynamic library for iOS 5, 6, 7, 8, 9, 10, 11, 12, 13, and 14.

## What is AppSync Unified?

AppSync Unified is a tweak that allows users to freely install ad-hoc signed, fakesigned, or unsigned IPA app packages on their iOS devices that iOS would otherwise consider invalid.

Some popular use cases include:

* Installing freely-distributed apps that are unavailable from the App Store without having to re-sign the apps in question every 7 days (if the user does not have a subscription to the Apple Developer Program)
* Assisting in the development of iOS applications with Xcode
* Cloning or downgrading already-installed apps

---

## How do I install AppSync Unified on my jailbroken iOS device?

AppSync Unified is available from **Karen's Repo: https://cydia.akemi.ai/** ([Tap here on your device to automatically add the repo!](https://cydia.akemi.ai/add.php))

If you do not see AppSync Unified listed in Karen's Repo, then that just means you have another repository added that is also hosting a copy of AppSync Unified under the same package ID.

**_Please_ only ever install the official, unmodified release from Karen's Repo for your own safety!** Third-party modified versions from other repositories can and _have_ broken various users' iOS installations in the past.

By installing third-party modified versions of _any system tweak_ like AppSync Unified, you are putting the security and stability of your iOS device and your personal data at risk.

---

## Help! I installed AppSync Unified, but it doesn't seem to be working after I resprung from Cydia/Zebra/Sileo/etc.!

If AppSync Unified is not working after installation, reboot your device or run ldrestart to activate it. You will only need to do this ONCE.

This issue appears to be caused by what …seems like a Cydia Substrate/Substitute bug(?) that's resurfaced from years ago, and occurs _really_ rarely, so it's an absolute nightmare of a bug. It's especially frustrating for me since I'm such a perfectionist when it comes to software development, too ww (🍍˃̶͈̀ロ˂̶͈́)੭ꠥ⁾⁾

**For the curious developers among you:** AppSync Unified's `postinst` binary (see [pkg-actions.m](pkg-actions/pkg-actions.m)) restarts `installd` via `launchctl` — for some reason though, it seems like Cydia Substrate and/or Substitute doesn't always inject the dylib properly into `installd` until you run `ldrestart` or reboot.

I tried _really_ hard to determine the cause of this, but I really have no idea what could be causing this. The dylib has _long_ since been written to the filesystem by the time `postinst` was _executed_, let alone when `launchctl` was even called by `posix_spawn`.

I guess for now, all I can do is inform people about the bug and how to resolve it. ⊂⌒~⊃｡Д｡🍍)⊃

Hopefully I'll be able to properly resolve this in time.

---

## Regarding piracy…

**Please do NOT use AppSync Unified for piracy.**

AppSync Unified is a development tool designed for app developers first and foremost, alongside other valid legal uses that I support — a few of which are outlined above.

**Software piracy is illegal.** Please support the developers of the iOS software you use, whether they be app developers on the App Store or tweak developers on Chariz/Dynastic/etc.

They're just trying to make a living too, much like you and I.

---

## How do I build AppSync Unified?

First, make sure you have [Theos](https://github.com/theos/theos) installed. If you don't, [please refer to the official documentation](https://github.com/theos/theos/wiki/Installation) on how to set up Theos on your operating system of choice.

Once you've confirmed that you have Theos installed, open up Terminal and run the following commands:

```
git clone https://github.com/angelXwind/AppSync.git
cd AppSync
make
make package
```

And you should have a freshly built *.deb package file of AppSync Unified!

---

## Do I need to do anything in order to use Xcode with AppSync Unified?

No, not unless you're using Xcode 6 or below.

As long as you're using a … _reasonably_ modern version of Xcode (7 or above, really), just use Xcode with your iOS device as you would normally!

That being said, if for some reason you _are_ using Xcode 6 or below, please follow this old tutorial I wrote up all the way back in 2014: [Tutorial: How to use AppSync Unified for development with Xcode 6 or below](https://akemi.ai/?page/how2asu)

---

## I'm a developer — do you have a rough high-level explanation as to how this all works?

As of AppSync Unified 90.0, ASU is split into two separate dynamic libraries — `AppSyncUnified-installd` and `AppSyncUnified-FrontBoard`.

### `AppSyncUnified-installd`

`AppSyncUnified-installd` injects into — you guessed it — `installd`, which is where the vast majority of ASU's functionality resides in.

AppSync Unified utilises Cydia Substrate's dynamic hooking function `MSHookFunction()` (which is also shimmed appropriately for systems that use Substitute as their code injection platform instead) to bypass `installd`'s signature checks. For iOS 13 and below, the main function being modified is `MISValidateSignatureAndCopyInfo()`, while on iOS 14 and above, it is `MISValidateSignatureAndCopyInfoWithProgress()`.

Using `MSFindSymbol()`, AppSync Unified determines which function is present on the system it's currently running on and appropriately hooks the correct one.

When iOS makes a request to install an app, one of the two functions mentioned above will be called, and AppSync Unified's injected `ASU_MISValidateSignatureAndCopyInfo()` function will take over.

If the app in question has valid signing information, AppSync Unified will not make any modifications to it, and simply pass the information along to the original Apple-implemented function, letting the app installation process carry on as if the system was not modified at all.

On the other hand, if the app contains invalid signing information, AppSync Unified will generate the appropriate signing information required and pass it along to the system. As of AppSync Unified 90.0, this process also includes code directory hash value (`cdhash`) computation.

AppSync Unified also hooks two other functions — `SecCertificateCreateWithData()` and `SecCertificateCopySubjectSummary()`. The modifications work in pretty much the same way as above — if the original certificate is valid, don't touch anything at all. If it isn't valid, then just… present a valid certificate to iOS.

### `AppSyncUnified-FrontBoard`

AppSync Unified 90.0 introduced a second dynamic library that injects into the `FrontBoard` and `FrontBoardServices` private frameworks. This is done in order to bypass a set of signature verifications that are performed at app runtime, generally used for timed app expirations.

That being said, the modifications are actually… incredibly simple.

On iOS 9.3.x to iOS 13, AppSync Unified hooks the Objective-C methods `-(NSUInteger) trustStateWithTrustRequiredReasons:(NSUInteger *)reasons` and `-(NSUInteger) trustState` found in the class `FBApplicationTrustData`, and forces both methods to always return the value used to signal to iOS that the app that the user is attempting to launch is valid and trusted.

On iOS 14 and above, it's… basically the same thing, but targetting a different method — `-(NSUInteger) trustStateForApplication:(id)application` found in the class `FBSSignatureValidationService` — since Apple moved the relevant functionality from `FrontBoard` to `FrontBoardServices`.

…

And that's about it! This explanation is obviously _incredibly_ simplified (the best explanation is just to read the code!), but hopefully it gives you a grasp on how everything works. c:

---

## License

Licensed under [GPLv3](http://www.gnu.org/copyleft/gpl.html).