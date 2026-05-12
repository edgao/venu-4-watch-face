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
    var historyFreshnessThreshold = new Time.Duration(60);

    var heartIcon;

    var width;
    var height;

    var temperatureLabel;
    var dateLabel;
    var timeLabel;
    var heartrateLabel;
    var stepsLabel;
    var stressLabel;
    var bodyBatteryLabel;
    var batteryLabel;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));

        heartIcon = WatchUi.loadResource(Rez.Drawables.HeartIcon);

        width = dc.getWidth();
        height = dc.getHeight();

        temperatureLabel = View.findDrawableById("Temperature") as Text;
        dateLabel = View.findDrawableById("Date") as Text;
        timeLabel = View.findDrawableById("TimeLabel") as Text;
        heartrateLabel = View.findDrawableById("HeartRate") as Text;
        stepsLabel = View.findDrawableById("Steps") as Text;
        stressLabel = View.findDrawableById("Stress") as Text;
        bodyBatteryLabel = View.findDrawableById("BodyBattery") as Text;
        batteryLabel = View.findDrawableById("Battery") as Text;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var now = Time.now();
        var stats = System.getSystemStats();
        var info = ActivityMonitor.getInfo();
        var date = Time.Gregorian.info(now, Time.FORMAT_MEDIUM);

        var temperature = Weather.getCurrentConditions().temperature;
        var temperatureStr;
        if (temperature != null) {
            // temperature is in celsius; convert to fahrenheit
            temperatureStr = (temperature * 1.8 + 32).format("%d") + "°";
        } else {
            temperatureStr = "--";
        }
        temperatureLabel.setText(temperatureStr);

        var dateString = Lang.format("$1$ $2$ $3$", [date.day_of_week, date.month, date.day.format("%02d")]);
        dateLabel.setText(dateString);

        var timeString = Lang.format("$1$:$2$", [date.hour, date.min.format("%02d")]);
        timeLabel.setText(timeString);

        var heartRate = SensorHistory.getHeartRateHistory(historyQuery).next();
        var heartRateStr;
        if (isHistorySampleFresh(heartRate, now)) {
            heartRateStr = heartRate.data.format("%d");
        } else {
            heartRateStr = "--";
        }
        heartrateLabel.setText(heartRateStr);

        var stepsStr;
        if (info.steps != null) {
            stepsStr = info.steps.format("%d");
        } else {
            stepsStr = "--";
        }
        stepsLabel.setText(stepsStr);

        var stressStr;
        var stress = SensorHistory.getStressHistory(historyQuery).next();
        if (isHistorySampleFresh(stress, now)) {
            stressStr = stress.data.format("%d");
        } else {
            stressStr = "--";
        }
        stressLabel.setText(stressStr);

        var bodyBattery = SensorHistory.getBodyBatteryHistory(historyQuery).next();
        var bodyBatteryStr;
        if (isHistorySampleFresh(bodyBattery, now)) {
            bodyBatteryStr = bodyBattery.data.format("%d");
        } else {
            bodyBatteryStr = "--";
        }
        bodyBatteryLabel.setText(bodyBatteryStr);

        batteryLabel.setText(Math.round(stats.battery).format("%02d") + "%");

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        dc.drawScaledBitmap(
            width * 0.43,
            height * 0.59,
            width * 0.05,
            height * 0.05,
            heartIcon
        );
        dc.drawScaledBitmap(
            width * 0.53,
            height * 0.59,
            width * 0.05,
            height * 0.05,
            // TODO steps icon
            heartIcon
        );
        dc.drawScaledBitmap(
            width * 0.43,
            height * 0.74,
            width * 0.05,
            height * 0.05,
            // TODO stress icon
            heartIcon
        );
        dc.drawScaledBitmap(
            width * 0.53,
            height * 0.74,
            width * 0.05,
            height * 0.05,
            // TODO body battery icon
            heartIcon
        );
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
        if (isInsideLabel(coord, temperatureLabel, Graphics.TEXT_JUSTIFY_CENTER)) {
            return Complications.COMPLICATION_TYPE_CURRENT_WEATHER;
        }
        return null;
    }

    private function isHistorySampleFresh(sample as SensorHistory.SensorSample?, now as Time.Moment) as Boolean {
        if (sample == null || sample.data == null) {
            return false;
        }
        return sample.when.add(historyFreshnessThreshold).greaterThan(now);
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
