import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.Time.Gregorian;

class face1View extends WatchUi.WatchFace {

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
        var stats = System.getSystemStats();
        var date = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

        var timeString = Lang.format("$1$:$2$", [date.hour, date.min.format("%02d")]);
        var timeLabel = View.findDrawableById("TimeLabel") as Text;
        timeLabel.setText(timeString);

        var dateLabel = View.findDrawableById("Date") as Text;
        var dateString = Lang.format("$1$ $2$ $3$", [date.day_of_week, date.month, date.day.format("%02d")]);
        dateLabel.setText(dateString);

        var topLeftLabel = View.findDrawableById("DataTopLeft") as Text;
        topLeftLabel.setText("asdf");

        var topRightLabel = View.findDrawableById("DataTopRight") as Text;
        topRightLabel.setText("qwer");

        var bottomLeftLabel = View.findDrawableById("DataBottomLeft") as Text;
        bottomLeftLabel.setText("zxcv");

        var bottomRightLabel = View.findDrawableById("DataBottomRight") as Text;
        bottomRightLabel.setText("jk;l");

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

}
