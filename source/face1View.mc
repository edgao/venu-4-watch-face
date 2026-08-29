import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

using Toybox.Complications;
using Toybox.Time;
using Toybox.SensorHistory;
using Toybox.Weather;

class face1View extends WatchUi.WatchFace {
    var historyQuery = {
            :period => 1,
            :order => SensorHistory.ORDER_NEWEST_FIRST
        };
    var freshSampleThreshold = new Time.Duration(5);
    var sampleThreshold1 = new Time.Duration(15);
    var sampleThreshold2 = new Time.Duration(30);
    var sampleThreshold3 = new Time.Duration(60);

    var width;
    var height;

    var dateLabel;
    var timeLabel;
    var heartrateLabel;
    var stepsLabel;
    var stressLabel;
    var bodyBatteryLabel;
    var batteryLabel;
    var notificationIcon;
    var notificationLabel;
    var noBluetoothIcon;

    var lastHeartRate;
    var lastHeartRateTime;
    var lastStress;
    var lastStressTime;
    var lastBodyBattery;
    var lastBodyBatteryTime;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));

        width = dc.getWidth();
        height = dc.getHeight();

        dateLabel = View.findDrawableById("Date") as Text;
        timeLabel = View.findDrawableById("TimeLabel") as Text;
        heartrateLabel = View.findDrawableById("HeartRate") as Text;
        stepsLabel = View.findDrawableById("Steps") as Text;
        stressLabel = View.findDrawableById("Stress") as Text;
        bodyBatteryLabel = View.findDrawableById("BodyBattery") as Text;
        batteryLabel = View.findDrawableById("Battery") as Text;

        notificationIcon = View.findDrawableById("NotificationIcon") as Bitmap;
        notificationLabel = View.findDrawableById("NotificationLabel") as Text;
        noBluetoothIcon = View.findDrawableById("NoBluetoothIcon") as Bitmap;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var now = Time.now();
        var date = Time.Gregorian.info(now, Time.FORMAT_MEDIUM);
        var activityInfo = Activity.getActivityInfo();
        var activityMonitorInfo = ActivityMonitor.getInfo();

        var dateString = Lang.format("$1$ $2$ $3$", [date.day_of_week, date.month, date.day.format("%02d")]);
        dateLabel.setText(dateString);

        var timeString = Lang.format("$1$:$2$", [date.hour, date.min.format("%02d")]);
        timeLabel.setText(timeString);

        var liveHeartrate = activityInfo.currentHeartRate;
        if (liveHeartrate != null) {
            lastHeartRate = liveHeartrate;
            lastHeartRateTime = now;
            heartrateLabel.setText(liveHeartrate.format("%d"));
        } else {
            var heartRate = SensorHistory.getHeartRateHistory(historyQuery).next();
            if (heartRate != null && heartRate.data != null) {
                lastHeartRate = heartRate.data;
                lastHeartRateTime = heartRate.when;
            }
            heartrateLabel.setText(historySampleToString(heartRate, now, lastHeartRate, lastHeartRateTime, false));
        }

        var stepsStr;
        if (activityMonitorInfo.steps != null) {
            stepsStr = activityMonitorInfo.steps.format("%d");
        } else {
            stepsStr = "--";
        }
        stepsLabel.setText(stepsStr);

        if (activityMonitorInfo.stressScore != null) {
            lastStress = activityMonitorInfo.stressScore;
            lastStressTime = now;
            stressLabel.setText(activityMonitorInfo.stressScore.format("%d"));
        } else {
            var stress = SensorHistory.getStressHistory(historyQuery).next();
            if (stress != null && stress.data != null) {
                lastStress = stress.data;
                lastStressTime = stress.when;
            }
            stressLabel.setText(historySampleToString(stress, now, lastStress, lastStressTime, false));
        }
        if (lastStress != null) {
            if (lastStress <= 25) {
                stressLabel.setColor(Graphics.COLOR_WHITE);
            } else if (lastStress <= 50) {
                stressLabel.setColor(Graphics.COLOR_YELLOW);
            } else if (lastStress <= 75) {
                stressLabel.setColor(Graphics.COLOR_ORANGE);
            } else {
                stressLabel.setColor(Graphics.COLOR_RED);
            }
        }

        var bodyBattery = SensorHistory.getBodyBatteryHistory(historyQuery).next();
        if (bodyBattery != null && bodyBattery.data != null) {
            lastBodyBattery = bodyBattery.data;
            lastBodyBatteryTime = now;
        }
        bodyBatteryLabel.setText(historySampleToString(bodyBattery, now, lastBodyBattery, lastBodyBatteryTime, true));

        batteryLabel.setText(Math.round(System.getSystemStats().battery).format("%02d") + "%");

        var deviceSettings = System.getDeviceSettings();
        var hasNotifications = deviceSettings.notificationCount > 0;
        notificationIcon.setVisible(hasNotifications);
        notificationLabel.setVisible(hasNotifications);
        notificationLabel.setText(deviceSettings.notificationCount.toString());
        noBluetoothIcon.setVisible(!deviceSettings.phoneConnected);

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    function getClickTarget(coord as [Number, Number]) as Complications.Type? {
        // hardcode positions. They're not strictly related to the label position/sizes.
        if (isInside(coord, 0, height * 0.55, width * 0.5, height * 0.16)) {
            return Complications.COMPLICATION_TYPE_HEART_RATE;
        }
        if (isInside(coord, width * 0.5, height * 0.55, width * 0.5, height * 0.16)) {
            return Complications.COMPLICATION_TYPE_STEPS;
        }
        if (isInside(coord, 0, height * 0.71, width * 0.5, height * 0.16)) {
            return Complications.COMPLICATION_TYPE_STRESS;
        }
        if (isInside(coord, width * 0.5, height * 0.71, width * 0.5, height * 0.16)) {
            return Complications.COMPLICATION_TYPE_BODY_BATTERY;
        }
        return null;
    }

    private function historySampleToString(sample as SensorHistory.SensorSample?, now as Time.Moment, lastKnownValue as Number, lastKnownValueTime as Time.Moment, leftJustify as Boolean) as String {
        if (sample == null || sample.data == null) {
            if (lastKnownValue != null) {
                return addAffix(lastKnownValue.format("%d"), historySampleAgeAffix(lastKnownValueTime, now), leftJustify);
            } else {
                return addAffix("--", "~", leftJustify);
            }
        }
        return addAffix(sample.data.format("%d"), historySampleAgeAffix(sample.when, now), leftJustify);
    }

    private function addAffix(dataStr as String, ageAffix as String, leftJustify as Boolean) as String {
        if (leftJustify) {
            return dataStr + ageAffix;
        } else {
            return ageAffix + dataStr;
        }
    }

    private function historySampleAgeAffix(timestamp as Time.Moment, now as Time.Moment) as String {
        var age = now.subtract(timestamp) as Time.Duration;
        if (age.lessThan(freshSampleThreshold)) {
            return "";
        }
        if (age.lessThan(sampleThreshold1)) {
            return "*";
        }
        if (age.lessThan(sampleThreshold2)) {
            return "**";
        }
        if (age.lessThan(sampleThreshold3)) {
            return "?";
        }
        return "??";
    }

    private function isInside(
        coord as [Number, Number],
        xmin as Number,
        ymin as Number,
        width as Number,
        height as Number
    ) as Boolean {
        var x = coord[0];
        var y = coord[1];
        return xmin <= x && x <= xmin + width && ymin <= y && y <= ymin + height;
    }

}
