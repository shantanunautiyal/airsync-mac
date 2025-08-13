# AirSync 2.0 macOS app written in Swift

Min : macOS 14.5

[![AirSync demo](https://img.youtube.com/vi/HDv0Hu9z294?si=dgycryP1T8QvPJYa/0.jpg)](https://www.youtube.com/watch?v=HDv0Hu9z294?si=dgycryP1T8QvPJYa)

### During beta testing, You can use the code ```i-am-a-tester``` to try out and test AirSync+ features. Also these + features are subject to change and currently they are limited because to test if the workflow works.

<p align="center">
  <img src="https://github.com/user-attachments/assets/7c81bd2a-3799-44f2-b63a-350344f68e42" width="30%" />
  <img src="https://github.com/user-attachments/assets/58996c84-083f-4464-b0a5-bce069935898" width="30%" />
  <img src="https://github.com/user-attachments/assets/3f9d3113-1e16-4071-b1fc-f8f33a24c439" width="30%" />
</p>


![1](https://github.com/user-attachments/assets/8abdd977-6f8b-4037-b277-9457e65a6255)


## [Wireless ADB setup](https://github.com/sameerasw/airsync-android/blob/main/README.md#adb-setup)

## Installation and Troubleshooting

### Make sure to allow network access (may appear on first outgoing and incoming connections

<img width="200" alt="image" src="https://github.com/user-attachments/assets/b602edbc-ca2e-42f8-b491-b5f9bacf2dcc" />

### First time you runt he app, it may not be allowed to be opened by the mac. If so, head to the privacy settings and scroll down till you find the "run/ open anyway" button and authenticate to confirm.

<p align="center">
  <img  src="https://github.com/user-attachments/assets/039a592e-f280-4825-99e9-f1b694e2976b" width="45%" />
  <img  src="https://github.com/user-attachments/assets/d7105b10-7173-44d4-a8a0-62ffdf21f03d" width="45%" />
</p>


You may need to run the below in terminal to quarantine the app. (Not necessary)
```
xattr -r -d com.apple.quarantine /path/to/AirSync.app
```

### Or maybe you will need to right/ Ctrl click the app and pick open from the context menu.

---

# Documentation

## Communication

- Currently utilizing a web socket for the communication between the mac which is the server and the Android device as the client.

## Security

- Non encrypted local network usage for now via websocket protocol.
- Will be looking into device to device encryption in the future as it’s very possible, just that I’m needing to do more research on it.

## Authentication

- Currently done through a QR code scan which includes the websocket host IP, Port, Device name and the AirSync+ availability.
- Once scanned with any camera, Google lens based or any scanner that can handle Android intents, It will prompt the user to open the AirSync app.
- It will present the user with an authentication dialog to accept the connection and once done, it will start communication

## How it communicate?

- JSON objects via websocket, As an example, the initial authentication response from the Android will be it’s IP, Name and some other details.
- Then there will be another a bit heavy network call which gathers, encodes and sends all the app icons to the mac client for caching them for easier usage when displaying notifications. This will get improved over time.
- Along with that, the initial call with device status will be shared which includes battery %, volume and currently playing media and related info. This will be a less frequent polling but if there is a detected action like a change of media playback, it may update instantly.
- Then at last, the confirmation message will appear from the android to the mac after the setup is completed.
- Pretty much the same with the clipboard sync. It detects, syncs the text.

## Permissions usage

- This is an important topic on explaining the sensitive permission usage on mostly the Android app in order to provide features with transparency.

<aside>
💡

### Android app

### Notification read access

- This permission is necessary in order to read and listen to new notifications on Android and then to continue syncing them. Also extends it’s usage to media player as it’s also a notification that holds playback information.

### Notification post permission

- Starting from Android 14, apps now have to request permission in order to send notifications. This is not yet utilized well in AirSync but the current usage is to display the connected device’s status as a persistent notification. There will be more uses of this.

### Network access

- Well, that is self explanatory
</aside>

<aside>
💡

### macOS app

### Network access

- App requires incoming and outgoing local network access for the websocket to perform and connect to the android devices
- App may use the internet for updates which are now built-in tot he app itself for easier updating process.

### Notification post permission

- To display Android notifications

### Local cache/ storage

- To store app data for persistence.
</aside>

## Inspiration?

- AirSync 1.0, Yes, I had an initial version of the application vibe coded a while ago which was not close to being user friendly. But it is the base
- The ACTUAL inspiration, It’s been a thing I wanted to do for a while.. for many reasons
    - I could just leave my phone somewhere in the home and continue on my day without missing anything
    - Less distractions
    - I don’t have to log into my work account on everywhere to get notified
    - Sometimes, mobile apps are more reliable when it comes to notifying
    - Less apps to run on my poor mac
    - Also why not?

## Features

Now we into the goodies,

- Sync Android notifications to mac
- Take actions with the notifications (currently dismissing)
- Clipboard sync (there are improvements to be made)
- Sync Android battery status to mac
- Show Android now playing and control
- Share text by sharing it tot he AirSync app in android

And more… Especially more to come and planned.

- Wireless ADB assist
- scrcpy integration
- ~~iPhone~~ Android Mirroring and remote access assist
- Synced widgets on both devices
- QS tiles on Android for easier actions
- Run in macOS menubar
- Sync mac device status to Android
- Low battery alerts
- Take actions with notifications, maybe reply
- Maybe file share, but use Blip instead
- Live activities?
- Remotely lock devices?

The list goes on, You are welcome to open feature requests and inspire me for new ideas. 


## Contributors <3
<a href="https://github.com/sameerasw/airsync-mac/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=sameerasw/airsync-mac" />
</a>


<a href="https://star-history.com/#sameerasw/airsync-mac&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=sameerasw/airsync-mac&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=sameerasw/airsync-mac&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=sameerasw/airsync-mac&type=Date" />
 </picture>
</a>

## Thanks!

- To you, seriously…
- To my community mostly known as TIDWIB (Things I Do When I’m Bored ….. see the connection)
- May sound weird but AI, Yeah, without that deep research, assistant in helpless topics, explanations, occasional detonations and all lead to the rapid development of AirSync. Without this, how da hell do I implement a notification listener without weeks of study? Yeah, if you know how to use it efficiently, it is a damn good buddy to do things that you never could imagine.
- All the reddit peeps for showing that this is actually a thing that they wanted.
- All the libraries, apps and tools used for development and their creators. Issue volunteers, reddit community helpers…
- My sleep schedule… the lack of.

### Libraries used
- [dagronf/QRCode](https://github.com/dagronf/QRCode)
- [httpswift/swifter](https://github.com/httpswift/swifter)


### File Structure
```
📦 airsync-mac
├─ .github
├─ .gitignore
├─ AirSync.xcodeproj
├─ COMMERCIAL-EULA.txt
├─ CONTRIBUTING.md
├─ LICENSE
├─ README.md
├─ airsync-mac
│  ├─ Assets.xcassets
│  ├─ Components
│  │  ├─ Buttons
│  │  ├─ Containers
│  │  ├─ Custom
│  │  └─ Plus
│  ├─ Constants
│  ├─ Core
│  │  ├─ AppState.swift
│  │  ├─ Util
│  │  │  ├─ Extensions
│  │  │  ├─ Icons
│  │  └─ WebSocket
│  ├─ Info.plist
│  ├─ Model
│  ├─ Resources
│  │  ├─ adb
│  │  ├─ scrcpy
│  ├─ Screens
│  │  ├─ HomeScreen
│  │  │  ├─ AppContentView.swift
│  │  │  ├─ HomeView.swift
│  │  │  ├─ NotificationView
│  │  │  ├─ PhoneView
│  │  │  └─ SidebarView.swift
│  │  ├─ ScanScreen
│  │  └─ Settings
│  └─ airsync_macApp.swift @main
├─ appcast.xml @update tracker
```
©generated by [Project Tree Generator](https://woochanleee.github.io/project-tree-generator)


