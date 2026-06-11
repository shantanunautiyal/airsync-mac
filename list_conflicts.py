import sys
import re
import os

files = [
    "AirSync.xcodeproj/project.pbxproj",
    "airsync-mac/Core/AppState.swift",
    "airsync-mac/Core/QuickConnect/QuickConnectManager.swift",
    "airsync-mac/Core/Util/CLI/ADBConnector.swift",
    "airsync-mac/Core/Util/NotificationDelegate.swift",
    "airsync-mac/Core/WebSocket/WebSocketServer.swift",
    "airsync-mac/Model/TabIdentifier.swift",
    "airsync-mac/Screens/HomeScreen/AppContentView.swift",
    "airsync-mac/Screens/HomeScreen/AppsView/AppGridView.swift",
    "airsync-mac/Screens/HomeScreen/Components/CallWindowView.swift",
    "airsync-mac/Screens/HomeScreen/NotificationView/NotificationCardView.swift",
    "airsync-mac/Screens/HomeScreen/PhoneView/DeviceStatusView.swift",
    "airsync-mac/Screens/HomeScreen/PhoneView/MediaPlayerView.swift",
    "airsync-mac/Screens/HomeScreen/SidebarView.swift",
    "airsync-mac/Screens/MenubarView/MenubarView.swift",
    "airsync-mac/Screens/Settings/SettingsView.swift"
]

for f in files:
    if not os.path.exists(f): continue
    with open(f, 'r') as file:
        content = file.read()
    conflicts = re.findall(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [a-f0-9]+', content, re.DOTALL)
    if conflicts:
        print(f"=== {f} ===")
        for i, (head, incoming) in enumerate(conflicts):
            print(f"Conflict {i+1}:")
            print("HEAD:")
            print(head)
            print("INCOMING:")
            print(incoming)
            print("-" * 40)
