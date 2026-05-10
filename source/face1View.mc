import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

using Toybox.Time;
using Toybox.SensorHistory;
using Toybox.Weather;

class face1View extends WatchUi.WatchFace {
    var historyQuery = {
            :period => 1,
            :order => SensorHistory.ORDER_NEWEST_FIRST
        };
    var historyFreshnessThreshold = new Time.Duration(60);

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
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

        var temperatureLabel = View.findDrawableById("Temperature") as Text;
        var temperature = Weather.getCurrentConditions().temperature;
        var temperatureStr;
        if (temperature != null) {
            // temperature is in celsius; convert to fahrenheit
            temperatureStr = (temperature * 1.8 + 32).format("%d") + "°";
        } else {
            temperatureStr = "--";
        }
        temperatureLabel.setText(temperatureStr);

        var timeString = Lang.format("$1$:$2$", [date.hour, date.min.format("%02d")]);
        var timeLabel = View.findDrawableById("TimeLabel") as Text;
        timeLabel.setText(timeString);

        var dateLabel = View.findDrawableById("Date") as Text;
        var dateString = Lang.format("$1$ $2$ $3$", [date.day_of_week, date.month, date.day.format("%02d")]);
        dateLabel.setText(dateString);

        var topLeftLabel = View.findDrawableById("DataTopLeft") as Text;
        var heartRate = SensorHistory.getHeartRateHistory(historyQuery).next();
        var heartRateStr;
        if (isHistorySampleFresh(heartRate, now)) {
            heartRateStr = heartRate.data.format("%d");
        } else {
            heartRateStr = "--";
        }
        topLeftLabel.setText(heartRateStr);

        var topRightLabel = View.findDrawableById("DataTopRight") as Text;
        var stepsStr;
        if (info.steps != null) {
            stepsStr = info.steps.format("%d");
        } else {
            stepsStr = "--";
        }
        topRightLabel.setText(stepsStr);

        var bottomLeftLabel = View.findDrawableById("DataBottomLeft") as Text;
        var stressStr;
        var stress = SensorHistory.getStressHistory(historyQuery).next();
        if (isHistorySampleFresh(stress, now)) {
            stressStr = stress.data.format("%d");
        } else {
            stressStr = "--";
        }
        bottomLeftLabel.setText(stressStr);

        var bottomRightLabel = View.findDrawableById("DataBottomRight") as Text;
        var bodyBattery = SensorHistory.getBodyBatteryHistory(historyQuery).next();
        var bodyBatteryStr;
        if (isHistorySampleFresh(bodyBattery, now)) {
            bodyBatteryStr = bodyBattery.data.format("%d");
        } else {
            bodyBatteryStr = "--";
        }
        bottomRightLabel.setText(bodyBatteryStr);

        var batteryLabel = View.findDrawableById("Battery") as Text;
        batteryLabel.setText(Math.round(stats.battery).format("%02d") + "%");

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

    private function isHistorySampleFresh(sample as SensorHistory.SensorSample?, now as Time.Moment) as Boolean {
        if (sample == null) {
            return false;
        }
        return sample.when.add(historyFreshnessThreshold).greaterThan(now);
    }

}
