import re
import os

def resolve_file(filepath, resolver_func):
    if not os.path.exists(filepath): return
    with open(filepath, 'r') as f:
        content = f.read()
    
    resolved = re.sub(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [a-f0-9a-zA-Z]+', resolver_func, content, flags=re.DOTALL)
    
    with open(filepath, 'w') as f:
        f.write(resolved)

# 1. AppState.swift
def appstate_resolver(match):
    h = match.group(1)
    i = match.group(2)
    if "self.isPlus = UserDefaults" in h: return i  # Use incoming's deviceAdbSerials
    if "Gumroad().checkLicenseIfNeeded()" in h: return h # Keep our Gumroad check
    if "loadNotificationsFromDisk()" in h: return h + "\n" + i # Keep both
    if "notificationLaunchPreferences" in i: return h + "\n" + i # Keep both
    if "isMirrorActive" in h: return h + "\n" + i # Keep both
    if "transfers =" in h: return h + "\n" + i # Keep both
    return h

resolve_file("airsync-mac/Core/AppState.swift", appstate_resolver)

# 2. QuickConnectManager.swift
def quickconnect_resolver(match):
    h = match.group(1)
    i = match.group(2)
    if "import Combine" in i: return "import Darwin\nimport Combine"
    if "lastConnectedDevices[networkKey] = device" in h: return i
    if "wakeUpLastConnectedDevice" in h: return h # Keep our wake up logic
    if "sendHTTPWakeUpRequest" in h: return h + "\n" + i # Keep both? No, it's the success log. Keep INCOMING.
    return i

resolve_file("airsync-mac/Core/QuickConnect/QuickConnectManager.swift", quickconnect_resolver)

# 3. ADBConnector.swift
def adb_resolver(match):
    return match.group(2) # Keep INCOMING for ADB connection fixes

resolve_file("airsync-mac/Core/Util/CLI/ADBConnector.swift", adb_resolver)

# 4. TabIdentifier.swift
def tab_resolver(match):
    h = match.group(1)
    i = match.group(2)
    return h # Keep HEAD for tabs (transfers, calls, messages, health)

resolve_file("airsync-mac/Model/TabIdentifier.swift", tab_resolver)

