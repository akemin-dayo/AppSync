### Repo URL: https://cydia.akemi.ai/ ([Tap here on your device to automatically add the repo!](https://cydia.akemi.ai/add.php))

#### Support me with [Patreon](https://patreon.com/akemin_dayo), [PayPal (`karen@akemi.ai`)](https://paypal.me/akemindayo), or [Cryptocurrency](https://akemi.ai/?page/links#crypto)

(A full list of all available donation methods can be found [here](https://akemi.ai/?page/links#donate).)

Any support is _greatly_ appreciated, but donations are *not* and will *never* be necessary to use my software!

---

#**Changelog for 2.0 ([full changelog](https://cydia.akemi.ai/?page/ai.akemi.appinst-changelog))**

* Switched to using `libzip` to handle IPA extraction — thanks, ViRb3! This allows `appinst` to better handle some larger IPA files, as the previous implementation using the now-unmaintained `ZipZap` framework would sometimes cause a crash in this situation.

* Added some informative user-facing status information on iOS versions that use `MobileInstallation`. (※ iOS 5 〜 7)

* Reworded and improved user-facing messages.

* Made major changes to how `appinst` creates and handles temporary staging directories and app installation session IDs.

* Added proper handling for some potential edge cases involving running multiple `appinst` instances. (※ I do not recommend doing this. iOS can only install one app at a time anyway, so running multiple instances of `appinst` will merely add to the iOS app installation queue.)

* Added some error handling code to prevent `appinst` from theoretically potentially failing if two instances are launched in very quick succession.

* If the IPA fails to be copied to the temporary staging directory, `appinst` will now show suggest the user to check if they've run out of disk space, as that is the most likely cause of failure.

* `Improved `appinst`'s help message (accessible via the `-h` or `--help` arguments, or if `appinst` is run without any arguments specified)

* Removed the unnecessary `arm64e` Mach-O arch slice from the `appinst` binary.

* `appinst` will now always ensure that proper filesystem ownership and permissions are set on its temporary directory in order to prevent any possibility of an app installation failure if `appinst` was recently previously run as `root`. (That being said, this is rendered somewhat redundant by the other improvements in 2.0…)

* `appinst` will now always proactively clean up its temporary directory after an installation attempt, unlike previous versions which relied on iOS behaviour.

---

# `appinst`, a command-line IPA app installer for iOS 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, and 16.

App Installer is a command-line utility to install .ipa packages. Requires [AppSync Unified](https://cydia.akemi.ai/?page/ai.akemi.appsyncunified) to install unsigned/fakesigned/self-signed apps.

Usage: `appinst <ipa file>`