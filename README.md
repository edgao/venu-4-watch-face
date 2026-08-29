Customized watch face for my own needs.

# Features

* Touchscreen handlers as shortcuts to appropriate widgets
  * Battery shortcut doesn't work :(
* Fallback data display:
  * Prefer live data when possible
  * If not available, display historical sensor data
    * if <5s old, display normally
    * if <15s, display with `*` suffix
    * if <30s, display with `**`
    * if <60s, display with `?`
    * if >=60s, display with `??`
  * If historical sensor data also not available, display last-known value with `~`
* notification icon
* bluetooth connection-loss icon

# Building/sideloading

(presumably this can all be done from the command line?)

1. Install SDK from https://developer.garmin.com/connect-iq/sdk/
   1. This might error out - `bin/sdkmanager: error while loading shared libraries: libwebkit2gtk-4.0.so.37: cannot open shared object file: No such file or directory`
      ```shell
      distrobox create -n garmin-dev -i debian:12
      distrobox enter garmin-dev
      # inside the distrobox
      sudo apt install -y libsecret-1-0 libxkbcommon0 libsm6 libgtk-3-0 libwebkit2gtk-4.0-37
      ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so.62 /usr/lib/x86_64-linux-gnu/libjpeg.so.8
      ~/Downloads/garmin_sdk/bin/sdkmanager
      ```
      Install the latest SDK; install the latest API version of the device (venu 4 41mm)
   1. Follow instructions on that page to set up VS Code (i.e. install https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c)
      1. monkey c needs java installed, use `/home/tavst/.sdkman/candidates/java/current/bin/javac` as the JDK path
2. Run on simulator: VS Code `run and debug` (f5) should Just Work.
   1. If SDK was installed via distrobox, you have to manually launch the simulator first - `distrobox enter garmin-dev -- ~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.2.0-2026-06-09-92a1605b2/bin/connectiq`
3. Build+sideload https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/
   1. VS Code command palette (ctrl-shift-p) -> `Monkey C: Build for Device`
   2. Pick a device; create an empty directory for output files (e.g. `mkdir ~/Desktop/out`)
   3. Connect device via USB, unlock device
   4. Copy `face1.prg` to device's `GARMIN/APPS` directory
   5. Disconnect device
