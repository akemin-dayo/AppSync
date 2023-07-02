### Repo URL: https://cydia.akemi.ai/ ([Tap here on your device to automatically add the repo!](https://cydia.akemi.ai/add.php))

#### Support me with [Patreon](https://patreon.com/akemin_dayo), [PayPal (`karen@akemi.ai`)](https://paypal.me/akemindayo), or [Cryptocurrency](https://akemi.ai/?page/links#crypto)

(A full list of all available donation methods can be found [here](https://akemi.ai/?page/links#donate).)

Any support is _greatly_ appreciated, but donations are *not* and will *never* be necessary to use my software!

---

# Changelog for 2.1 ([full changelog](https://cydia.akemi.ai/?page/ai.akemi.appinst-changelog))

* Added support for "rootless" mode jailbreaks. ※ appinst does NOT currently work with the Dopamine jailbreak due to an IPC issue on that specific jailbreak. [[Twitter](https://twitter.com/akemin_dayo/status/1672982839405723651)] [[Fediverse (Mastodon, Misskey, etc.)](https://main.elk.zone/mstdn.jp/@akemin_dayo@mstdn.jp/110605445960091417)] [[Bluesky](https://bsky.app/profile/akemin-dayo.akemi.ai/post/3jyypxpxxpk25)]
* Added a warning message for users attempting to use appinst with Dopamine.
* Added more error logging so any failure states are more informative to the end user when and if they occur.
* Added the new entitlement `com.apple.security.exception.mach-lookup.global-name`.

---

# Important information regarding the Dopamine jailbreak

There is a known IPC (inter-process communication) issue with Dopamine that prevents apps from successfully installing.

It may also cause the TrollStore app to become temporarily unusable.

To restore TrollStore functionality, open your persistence helper (such as "GTA Car Tracker") and select "Refresh App Registrations".

If that does not help, perform a userspace reboot using the Dopamine app, or via the command line using `launchctl reboot userspace` or `ldrestart`.

For more information, please see: [[Twitter](https://twitter.com/akemin_dayo/status/1672982839405723651)] [[Fediverse (Mastodon, Misskey, etc.)](https://main.elk.zone/mstdn.jp/@akemin_dayo@mstdn.jp/110605445960091417)] [[Bluesky](https://bsky.app/profile/akemin-dayo.akemi.ai/post/3jyypxpxxpk25)]

---

# `appinst`, a command-line IPA app installer for iOS 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, and 16.

appinst is a command-line utility that allows you to install IPA packages.

[AppSync Unified](https://cydia.akemi.ai/?page/ai.akemi.appsyncunified) is required as a dependency in order to install ad-hoc signed, fakesigned, unsigned, or expired apps.

**Usage:** `appinst <path to IPA file>`