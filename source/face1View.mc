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
    var historyFreshnessThreshold = new Time.Duration(5);

    var width;
    var height;

    var dateLabel;
    var timeLabel;
    var heartrateLabel;
    var stepsLabel;
    var stressLabel;
    var bodyBatteryLabel;
    var batteryLabel;
    var noBluetoothIcon;

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

        var dateString = Lang.format("$1$ $2$ $3$", [date.day_of_week, date.month, date.day.format("%02d")]);
        dateLabel.setText(dateString);

        var timeString = Lang.format("$1$:$2$", [date.hour, date.min.format("%02d")]);
        timeLabel.setText(timeString);

        var heartRate = SensorHistory.getHeartRateHistory(historyQuery).next();
        heartrateLabel.setText(historySampleToString(heartRate, now));

        var info = ActivityMonitor.getInfo();
        var stepsStr;
        if (info.steps != null) {
            stepsStr = info.steps.format("%d");
        } else {
            stepsStr = "--";
        }
        stepsLabel.setText(stepsStr);

        var stress = SensorHistory.getStressHistory(historyQuery).next();
        stressLabel.setText(historySampleToString(stress, now));

        var bodyBattery = SensorHistory.getBodyBatteryHistory(historyQuery).next();
        bodyBatteryLabel.setText(historySampleToString(bodyBattery, now));

        batteryLabel.setText(Math.round(System.getSystemStats().battery).format("%02d") + "%");

        noBluetoothIcon.setVisible(!System.getDeviceSettings().phoneConnected);

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
        // hardcode justifications :/
        // doesn't seem like we can access this from the label instance
        if (isInsideLabel(coord, heartrateLabel, Graphics.TEXT_JUSTIFY_RIGHT)) {
            return Complications.COMPLICATION_TYPE_HEART_RATE;
        }
        if (isInsideLabel(coord, stressLabel, Graphics.TEXT_JUSTIFY_RIGHT)) {
            return Complications.COMPLICATION_TYPE_STRESS;
        }
        if (isInsideLabel(coord, stepsLabel, Graphics.TEXT_JUSTIFY_LEFT)) {
            return Complications.COMPLICATION_TYPE_STEPS;
        }
        if (isInsideLabel(coord, bodyBatteryLabel, Graphics.TEXT_JUSTIFY_LEFT)) {
            return Complications.COMPLICATION_TYPE_BODY_BATTERY;
        }
        if (isInsideLabel(coord, batteryLabel, Graphics.TEXT_JUSTIFY_CENTER)) {
            return Complications.COMPLICATION_TYPE_BATTERY;
        }
        return null;
    }

    private function isHistorySampleFresh(sample as SensorHistory.SensorSample?, now as Time.Moment) as Boolean {
        if (sample == null || sample.data == null) {
            return false;
        }
        return sample.when.add(historyFreshnessThreshold).greaterThan(now);
    }

    private function historySampleToString(sample as SensorHistory.SensorSample?, now as Time.Moment) as String {
        if (sample == null) {
            return "--";
        }
        if (sample.data == null) {
            return "--";
        }
        if (sample.when.add(historyFreshnessThreshold).greaterThan(now)) {
            return sample.data.format("%d");
        }
        return historySampleAgeToString(sample, now);
    }

    private function historySampleAgeToString(sample as SensorHistory.SensorSample?, now as Time.Moment) as String {
        var age = now.subtract(sample.when);
        return Lang.format("-$1$", [secondsToString(age.value())]);
    }

    private function secondsToString(seconds as Numeric) as String {
        if (seconds < 60) {
            return seconds + "s";
        } else if (seconds < 3600) {
            return Math.round(seconds / 60.0).format("%.0d") + "m";
        } else {
            return Math.round(seconds / 3600.0).format("%.0d") + "h";
        }
    }

    private function isInsideLabel(
        coord as [Number, Number],
        label as Text,
        justification as TextJustification
    ) as Boolean {
        var minX = label.locX;
        var minY = label.locY;
        var width = label.width;
        switch (justification) {
            case Graphics.TEXT_JUSTIFY_RIGHT: {
                minX = 0;
                width = self.width / 2;
                break;
            }
            case Graphics.TEXT_JUSTIFY_VCENTER: {
                minY = label.locY - label.height / 2;
                // fallthrough to CENTER case
            }
            case Graphics.TEXT_JUSTIFY_CENTER: {
                minX = 0;
                width = self.width;
                break;
            }
            case Graphics.TEXT_JUSTIFY_LEFT: {
                minX = self.width / 2;
                width = self.width / 2;
                break;
            }
            default: {
                throw new InvalidValueException("Unexpected justification value: " + justification);
            }
        }
        return isInside(
            coord,
            minX,
            minY,
            width,
            label.height
        );
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
