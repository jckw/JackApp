# Agent Guidelines

## Xcode Project Configuration

### Info.plist

Do not create a separate `Info.plist` file. This project uses `GENERATE_INFOPLIST_FILE = YES`, which means Xcode auto-generates the Info.plist at build time.

To add privacy descriptions or other Info.plist keys, use the `INFOPLIST_KEY_*` build settings in `project.pbxproj` instead. For example:

```
INFOPLIST_KEY_NSCameraUsageDescription = "Camera access is needed to take progress photos.";
INFOPLIST_KEY_NSFaceIDUsageDescription = "Face ID is used to protect your private progress photos.";
```

Adding both `INFOPLIST_FILE` and `GENERATE_INFOPLIST_FILE = YES` causes a build error: "Multiple commands produce Info.plist".
