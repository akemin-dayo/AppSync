**Cydia/APT Repo URL:** https://cydia.angelxwind.net/

[**Tap here to add my repo directly to Cydia!**](https://cydia.angelxwind.net/add.php)

[**Donate Using PayPal (`rei@angelxwind.net`)**](https://www.paypal.com/myaccount/transfer/send/external?recipient=rei@angelxwind.net&amount=&currencyCode=USD&payment_type=Gift) (donations are greatly appreciated, *but are not (and never will be) necessary!*)

[**IMPORTANT: Regarding AppSync Unified and Piracy**](https://www.reddit.com/r/jailbreak/comments/3oovnh/discussion_regarding_appsync_unified_ios_9_and/)

#**JulioVerne drama: tl;dr version**

* **I am working together with JulioVerne, _not_ "competing" against him**
* iOS 10 boot loop was caused by AppSync Unified crashing `installd` whenever Cydia ran `uicache`
* JulioVerne's fix uses the actual Apple certificate, which was why I was concerned about copyright.
* He is trustable, never did anything out of malice. And skilled. He just happens to crack software as a hobby.
* I recommended people to not install it out of fear it might be unstable, I wanted to analyse and thoroughly test the code first, then make a release if it was okay.
* The theories /r/jailbreak and Twitter come up with are hilarious. This isn't a popularity contest.

#**Fully explaining the drama surrounding JulioVerne**

Amazing. In the few hours that JulioVerne's release of AppSync Unified has existed, the entire jailbreak community seems to have set itself on fire in some capacity.

Let's clear some things up.

**"Competition"**

First off, a lot of people seem to think I am "competing" with JulioVerne or something. I'm not. I DM'd him on Twitter, asked to know what he did, he gave me the source code, all was fine.

Yes, I would have _preferred_ him make a pull request on GitHub (it's open-source!) or something instead of fragmenting the releases with his own, but he didn't exactly do anything _wrong_.

**What caused iOS 10 devices to drop like flies**

So, to defeat `installd`'s app signature checking, AppSync Unified returns some fake data when `installd` asks for the certificate. For reasons I do not yet fully comprehend, this causes `Security.framework` to crash `installd` on iOS 10.

Now, this normally would not be an issue... except that Cydia automatically runs `uicache` (for UX purposes) after you install _any_ package, regardless of whether or not an app was included. The thing is, `uicache` (or rather, the `LaunchServices` method it uses) makes use of `installd`, which now crashes.

So, as a result, the SpringBoard icon cache is now left in a half-finished, broken state, which causes SpringBoard to crash in a loop. And that's how the respring/"boot" loop problem happens.

**JulioVerne's changes, and my concerns/comments**

I will now attempt to explain, in simplified terms, how JulioVerne's changes work. For those who have programming knowledge, please refer to GitHub commit SHA-1 [`1e3e6f1348a50608c3891c92918d55a40c71c22d`](https://github.com/angelXwind/AppSync/commit/1e3e6f1348a50608c3891c92918d55a40c71c22d).

Anyway, JulioVerne worked around the Security.framework crash by modifying the code to make it return the _actual_ "Apple iPhone OS Application Signing" certificate.

The fact that an Apple certificate was embedded into the code (albeit in hex form) was what led me to be initially concerned about potential legal/copyright issues. However, the certificate is just a plain old public one, so it _should_ be fine.

Also, JulioVerne accidentally ended up breaking iOS 5/6 support in his release, due to usage of Objective-C methods that don't exist in those iOS versions ;P

I've fixed all of those issues, and improved the code for his method a bit.

**JulioVerne and his reputation**

I guess I need to address a few points here. First off, JulioVerne is a skilled developer/"hacker" (if you want to call him that). While I did make a number of modifications to his code for AppSync Unified, the core concept and idea behind his changes still remained, and well, _worked_.

So is he reputable? Trustable? I'd say so, yeah. He _did_ accidentally break some things, but that's just due to lack of testing.

"But he cracks tweaks like it's his day job! How could you say such things about someone like him!?"

...Eh. I'm talking about his skill and reputation here. He's clearly skilled _because_ he can crack as many tweaks as he can. And he's reputable because he hasn't done anything out of malice in his cracked tweaks. Sure, he's probably made mistakes and broken a few things, but I'm pretty sure everyone — including myself — has.

While I may not agree with his philosophy, that doesn't mean I can't respect and recognise him for his skills/knowledge/problem-solving skills.

**Why I recommended people to not install it**

Shortly after news of the release got out, I made a number of tweets, most of which basically just recommended people not use it.

Sure, I knew it _worked_ — but how well, was the question. The intent behind my words there was out of fear of device instability. I wanted to thoroughly analyse and test the code first, _and then_ make a proper release if everything checked out.

All that being said, the amount of theories that /r/jailbreak and Twitter came up with were amazingly hilarious. Jailbreak development isn't a popularity contest — use what works, and ideally, what works well. At least, that's my take on it.

#**Changelog ([full changelog](https://cydia.angelxwind.net/?page/net.angelxwind.appsyncunified-changelog))**

* Return the public "Apple iPhone OS Application Signing" intermediate certificate instead of `kSecMagicBytes` on iOS 10 to avoid a Security.framework crash — thanks JulioVerne!

#**Unified AppSync dynamic library for iOS 5 and above. Supports arm64.**

* AppSync Unified is **NOT** for piracy.

* AppSync Unified is for **freedom of iOS development with the official Xcode iOS SDK.**

* Jailbreaking is **NOT** for piracy.

* Jailbreaking is for **freedom of your iOS device.**

AppSync Unified is a tweak that patches installd to allow for the installation of unsigned IPA packages on an iOS device. This is particularly useful for iOS developers who are not enrolled in Apple's official iOS Developer Program, as it allows these developers to debug and test their apps on their own devices using modifications such as iOSOpenDev.

**I explain the problem with AppSync Unified and iOS piracy rather thoroughly [in this reddit post](https://www.reddit.com/r/jailbreak/comments/3oovnh/discussion_regarding_appsync_unified_ios_9_and/). Please give it a read.**

Again, AppSync is **NOT** meant to support piracy. Obviously it can still be used in that way, and I, nor anyone else can really stop you if you want to pirate, but please **don't pirate and support the developers!**