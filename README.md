<div align="center">
  <a href="https://github.com/adibendahan/SimplyFilterSMS-iOS"><img src="Simply%20Filter%20SMS/Resources/Assets.xcassets/AppIcon.appiconset/1024.png" width="256" height="256"></a>
  <h1>Simply Filter SMS</h1>
  <p>
    <b>Simply filter text messages from unknown senders using keywords</b>
  </p>
  <br>
  <br>
  <br>
</div>


[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]


Simply Filter SMS is a private, free and fast way to filter out spam text messages.

## Download

### iOS

[![](https://linkmaker.itunes.apple.com/assets/shared/badges/en-us/appstore-lrg.svg)](https://apps.apple.com/us/app/simply-filter-sms/id1603222959)

Requires iOS 15 or later.


## Screenshots

<p float="left">
<img width="250" src="Simply%20Filter%20SMS/Resources/Screenshots/English/iPhone%2013%20Pro%20Max/Filters.png">
<img width="250" src="Simply%20Filter%20SMS/Resources/Screenshots/English/iPhone%2013%20Pro%20Max/Add%20filter.png">
<img width="250" src="Simply%20Filter%20SMS/Resources/Screenshots/English/iPhone%2013%20Pro%20Max/Block%20a%20language.png">
</p>

## Features

### Private
Simply Filter SMS does not collect any data whatsoever. Nothing leaves your device.

### Free
Everything is free of charge. Forever. No in-app purchases, no nonsense. 
However, any help towards covering the yearly Apple Developer fee is greatly appreciated.

### Fast
The app is primarily a host of rules that integrates with iOS in a native, lightweight way, making the filtering efficient and fast.

### Simple
It's as easy as downloading the app, enabling it in iOS Messages settings ⭢ Message filtering and adding filters.

### Open Source
The source code is published under the permissive MIT license.

### Modern
Simply Filter SMS is written in Apple's latest programming paradigm Swift UI.

## FAQ

#### ***How does message filtering work?***

When you recive a text message from a number that is not in your contact list, Simply Filter SMS will filter it based on the following rules:
* If a text message contains any words from the Allow list it will be delivered regularly.
* If not, the message will be scanned for any denied words and in case any were found it will be delivered to the Junk folder.
* If the text doesn't contain any denied words, it will be delivered regularly.

#### ***Are my messages exposed to the app developer?***

No. Simply Filter SMS does not collect any information whatsoever, all message processing is done locally on your device without any logging.

#### ***What about iMessages and messages from my contats?***

Apple does not expose those messages to any developer, they remain completely private.

#### ***Where are the filtered messages?***

When a text message is tagged as junk it will still be available for reading on the Messages app under the Junk folder.

#### ***What's the difference between Junk/Transactions/Promotions folders?***

Not much, you can filter any word to any folder. Those folders are not customable in any way. Only messages filtered to the Junk folder will be delivered silently.

## Building from source

Just open the project on Xcode and build (Tested on Xcode 13.2.1). 

## Contributing

Simply Filter SMS is open for pull-request business.

## License

[MIT](https://github.com/adibendahan/SimplyFilterSMS-iOS/blob/main/LICENSE) 2022 © Adi Ben-Dahan. All rights reserved.


[contributors-shield]: https://img.shields.io/github/contributors/adibendahan/SimplyFilterSMS-iOS?style=for-the-badge
[contributors-url]: https://github.com/adibendahan/SimplyFilterSMS-iOS/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/adibendahan/SimplyFilterSMS-iOS?style=for-the-badge
[forks-url]: https://github.com/adibendahan/SimplyFilterSMS-iOS/network/members
[stars-shield]: https://img.shields.io/github/stars/adibendahan/SimplyFilterSMS-iOS?style=for-the-badge
[stars-url]: https://github.com/adibendahan/SimplyFilterSMS-iOS/stargazers
[issues-shield]: https://img.shields.io/github/issues/adibendahan/SimplyFilterSMS-iOS?style=for-the-badge
[issues-url]: https://github.com/adibendahan/SimplyFilterSMS-iOS/issues
[license-shield]: https://img.shields.io/github/license/adibendahan/SimplyFilterSMS-iOS?style=for-the-badge
[license-url]: https://github.com/adibendahan/SimplyFilterSMS-iOS/blob/main/LICENSE
