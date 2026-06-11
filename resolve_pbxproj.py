import re
with open("AirSync.xcodeproj/project.pbxproj", "r") as f:
    content = f.read()

# We want to replace conflict blocks.
# For PBXBuildFile and PBXFrameworksBuildPhase (which are lists of references), we just want both HEAD and INCOMING.
def replacer(match):
    head = match.group(1)
    incoming = match.group(2)
    # Check if this is the MARKETING_VERSION conflict
    if "MARKETING_VERSION" in head and "MARKETING_VERSION" in incoming:
        return incoming # Use 4.0.0
    elif "OTHER_LDFLAGS" in head and "OTHER_LDFLAGS" not in incoming:
        # If HEAD had OTHER_LDFLAGS and incoming didn't, we should keep it maybe? 
        # Actually incoming had it removed or it was modified. Let's keep both lines combined if it's properties.
        # Wait, the conflict was:
        # HEAD: MARKETING_VERSION = 2.5.2; OTHER_LDFLAGS = "";
        # INCOMING: MARKETING_VERSION = 4.0.0;
        return 'MARKETING_VERSION = 4.0.0;\nOTHER_LDFLAGS = "";'
    else:
        # Combine them for lists
        return head + "\n" + incoming

resolved = re.sub(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>> [a-f0-9]+', replacer, content, flags=re.DOTALL)

with open("AirSync.xcodeproj/project.pbxproj", "w") as f:
    f.write(resolved)
