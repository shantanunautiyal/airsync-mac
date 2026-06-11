import re
import os

def resolve_file(filepath, resolver_func):
    if not os.path.exists(filepath): return
    with open(filepath, 'r') as f:
        content = f.read()
    
    resolved = re.sub(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [a-f0-9a-zA-Z]+', resolver_func, content, flags=re.DOTALL)
    
    with open(filepath, 'w') as f:
        f.write(resolved)

# General resolver: just concatenate
def concat_resolver(match):
    h = match.group(1)
    i = match.group(2)
    return h + "\n" + i

# Resolve all remaining files with concatenation
files_to_concat = [
    "airsync-mac/Core/Util/NotificationDelegate.swift",
    "airsync-mac/Core/WebSocket/WebSocketServer.swift",
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

for f in files_to_concat:
    resolve_file(f, concat_resolver)

