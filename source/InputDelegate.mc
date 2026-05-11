import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

using Toybox.Complications;

class InputDelegate extends WatchUi.WatchFaceDelegate {
    var view;

    function initialize(view as face1View) {
        WatchFaceDelegate.initialize();
        self.view = view;
    }

    function onPress(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coord = clickEvent.getCoordinates();
        var clickTarget = view.getClickTarget(coord);
        if (clickTarget == null) {
            System.println("no trigger");
            return false;
        }
        Complications.exitTo(new Complications.Id(clickTarget));
        return true;
    }
}
