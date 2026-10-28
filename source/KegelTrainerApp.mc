// Kegel Trainer App for Garmin Watches
// Main Application Entry Point

using Toybox.Application as App;
using Toybox.WatchUi as Ui;

//! The main application class for Kegel Trainer
class KegelTrainerApp extends App.AppBase {

    //! Constructor
    function initialize() {
        AppBase.initialize();
    }

    //! Return the initial view for the application
    //! @return Array with the main view and its delegate
    function getInitialView() {
        var view = new KegelTrainerView();
        var delegate = new KegelTrainerDelegate(view);
        return ShotMode.initial(view, delegate);
    }
}
