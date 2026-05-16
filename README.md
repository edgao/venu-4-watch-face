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
   1. Follow instructions on that page to set up VS Code (i.e. install https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c)
2. Run on simulator: VS Code `run and debug` (f5) should Just Work.
3. Build+sideload https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/
   1. VS Code command palette (ctrl-shift-p) -> `Monkey C: Build for Device`
   2. Pick a device; create an empty directory for output files
   3. Connect device via USB, unlock device
   4. Copy `face1.prg` to device's `GARMIN/APPS` directory
   5. Disconnect device
