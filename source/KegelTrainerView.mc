// Kegel Trainer View
// Handles display and exercise timer logic

using Toybox.Lang;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Timer;
using Toybox.System as Sys;
using Toybox.Attention;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.ActivityRecording;
using Toybox.Activity;

//! Exercise states
enum {
    STATE_READY,      // Waiting to start
    STATE_COUNTDOWN,  // Initial 3-second countdown
    STATE_CONTRACT,   // Active contraction phase
    STATE_RELAX,      // Rest phase
    STATE_COMPLETE    // Workout finished
}

//! Main view class for the Kegel Trainer
class KegelTrainerView extends Ui.View {

    // Initial countdown duration
    private const COUNTDOWN_TIME = 3;

    // Settings (loaded from Properties)
    private var _contractTime as Lang.Number = 10;
    private var _relaxTime as Lang.Number = 5;
    private var _repsPerSeries as Lang.Number = 10;
    private var _numSeries as Lang.Number = 1;
    private var _activityName as Lang.String = "Kegel";
    private var _activityType as Lang.Number = 0;
    private var _disableRecording as Lang.Boolean = false;

    // State variables
    private var _state as Lang.Number;
    private var _currentRep as Lang.Number;
    private var _currentSeries as Lang.Number;
    private var _timeRemaining as Lang.Number;
    private var _timer as Timer.Timer?;
    private var _session as ActivityRecording.Session?;
    private var _pendingSaveDialog as Lang.Boolean = false;

    //! Constructor
    function initialize() {
        View.initialize();
        loadSettings();
        _state = STATE_READY;
        _currentRep = 1;
        _currentSeries = 1;
        _timeRemaining = COUNTDOWN_TIME;
        _timer = null;
        _session = null;
        _pendingSaveDialog = false;
    }

    //! Load settings from Properties
    private function loadSettings() {
        _repsPerSeries = Properties.getValue("repsPerSeries") as Lang.Number;
        _numSeries = Properties.getValue("numSeries") as Lang.Number;
        _contractTime = Properties.getValue("contractTime") as Lang.Number;
        _relaxTime = Properties.getValue("relaxTime") as Lang.Number;
        _activityName = Properties.getValue("activityName") as Lang.String;
        _activityType = Properties.getValue("activityType") as Lang.Number;
        _disableRecording = Properties.getValue("disableRecording") as Lang.Boolean;
    }

    //! Called when the view is brought to the foreground
    function onShow() {
        if (!isExerciseActive()) {
            loadSettings();
        }
        if (_timer == null) {
            _timer = new Timer.Timer();
        }
        // Resume the timer if an exercise was interrupted (e.g., by a notification).
        if (isExerciseActive()) {
            stopTimer();
            startTimer();
        }
    }

    //! Called when the view is removed from the screen
    function onHide() {
        // A notification or system overlay temporarily covered the app — keep
        // the timer and session alive so onShow() can resume seamlessly.
        if (isExerciseActive()) {
            return;
        }
        stopTimer();
        // Only discard if not in complete state (user hasn't chosen yet)
        if (_state != STATE_COMPLETE) {
            discardSession();
        }
    }

    //! Start the exercise routine
    function startExercise() {
        if (_state == STATE_READY || _state == STATE_COMPLETE) {
            loadSettings();
            _state = STATE_COUNTDOWN;
            _currentRep = 1;
            _currentSeries = 1;
            _timeRemaining = COUNTDOWN_TIME;
            startSession();
            startTimer();
            Ui.requestUpdate();
        }
    }

    //! Start activity recording session (keeps display active)
    private function startSession() {
        if (Toybox has :ActivityRecording) {
            if (_session == null || !_session.isRecording()) {
                var sport = Activity.SPORT_TRAINING;
                var subSport = Activity.SUB_SPORT_BREATHING;

                switch (_activityType) {
                    case 1:
                        subSport = Activity.SUB_SPORT_YOGA;
                        break;
                    case 2:
                        subSport = Activity.SUB_SPORT_CARDIO_TRAINING;
                        break;
                    case 3:
                        subSport = Activity.SUB_SPORT_FLEXIBILITY_TRAINING;
                        break;
                    case 4:
                        sport = Activity.SPORT_GENERIC;
                        subSport = Activity.SUB_SPORT_GENERIC;
                        break;
                }

                _session = ActivityRecording.createSession({
                    :name => _activityName,
                    :sport => sport,
                    :subSport => subSport
                });
                _session.start();
            }
        }
    }

    //! Stop and save activity session
    function saveSession() {
        if (_session != null && _session.isRecording()) {
            _session.stop();
            _session.save();
            _session = null;
        }
    }

    //! Stop and discard activity session
    function discardSession() {
        if (_session != null && _session.isRecording()) {
            _session.stop();
            _session.discard();
            _session = null;
        }
    }

    //! Show save confirmation dialog
    private function showSaveConfirmation() {
        var message = WatchUi.loadResource(Rez.Strings.SaveWorkout);
        var dialog = new Ui.Confirmation(message);
        Ui.pushView(dialog, new SaveConfirmationDelegate(self), Ui.SLIDE_UP);
    }

    //! Start the countdown timer (fires every second)
    (:noshot)
    private function startTimer() {
        if (_timer != null) {
            _timer.start(method(:onTimerTick), 1000, true);
        }
    }

    //! Screenshot mode: the screen stays as set, nothing ticks
    (:shotmode)
    private function startTimer() {}

    //! Screenshot mode: put the view in a state without starting a timer or a session
    (:shotmode)
    function shotState(state as Lang.Number, remaining as Lang.Number, rep as Lang.Number,
                       series as Lang.Number) as Void {
        _state = state;
        _timeRemaining = remaining;
        _currentRep = rep;
        _currentSeries = series;
    }

    //! Stop the countdown timer
    private function stopTimer() {
        if (_timer != null) {
            _timer.stop();
        }
    }

    //! Timer callback - called every second
    function onTimerTick() as Void {
        if (_state == STATE_COUNTDOWN || _state == STATE_CONTRACT || _state == STATE_RELAX) {
            _timeRemaining--;

            if (_timeRemaining <= 0) {
                transitionState();
            }

            Ui.requestUpdate();
        }
    }

    //! Handle state transitions
    private function transitionState() {
        if (_state == STATE_COUNTDOWN) {
            // Countdown finished, start first contraction
            _state = STATE_CONTRACT;
            _timeRemaining = _contractTime;
            doVibrate();
        } else if (_state == STATE_CONTRACT) {
            // Finished contraction
            if (_currentRep >= _repsPerSeries) {
                // Finished all reps in this series
                if (_currentSeries >= _numSeries) {
                    // Completed all series!
                    _state = STATE_COMPLETE;
                    stopTimer();
                    doVibrateComplete();
                    if (_disableRecording) {
                        // User opted out of saving — discard silently.
                        // ActivityRecording still ran to keep the display active.
                        discardSession();
                    } else {
                        // Flag the dialog to be shown from onUpdate() — calling
                        // Ui.pushView() directly from a timer callback corrupts
                        // the view stack and crashes on back-press.
                        _pendingSaveDialog = true;
                    }
                } else {
                    // Move to relax before next series
                    _state = STATE_RELAX;
                    _timeRemaining = _relaxTime;
                    doVibrateRelax();
                }
            } else {
                // Move to relax phase
                _state = STATE_RELAX;
                _timeRemaining = _relaxTime;
                doVibrateRelax();
            }
        } else if (_state == STATE_RELAX) {
            // Finished relaxation
            if (_currentRep >= _repsPerSeries) {
                // Start next series
                _currentSeries++;
                _currentRep = 1;
            } else {
                // Next rep in current series
                _currentRep++;
            }
            _state = STATE_CONTRACT;
            _timeRemaining = _contractTime;
            doVibrate();
        }
    }

    //! Trigger a single short vibration for contraction
    private function doVibrate() {
        if (Attention has :vibrate) {
            var vibeData = [new Attention.VibeProfile(50, 200)];
            Attention.vibrate(vibeData);
        }
    }

    //! Trigger two short vibrations for relax
    private function doVibrateRelax() {
        if (Attention has :vibrate) {
            var vibeData = [
                new Attention.VibeProfile(50, 200),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(50, 200)
            ];
            Attention.vibrate(vibeData);
        }
    }

    //! Trigger a longer vibration pattern for completion
    private function doVibrateComplete() {
        if (Attention has :vibrate) {
            var vibeData = [
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(100, 200),
                new Attention.VibeProfile(0, 100),
                new Attention.VibeProfile(100, 200)
            ];
            Attention.vibrate(vibeData);
        }
    }

    //! Reset the exercise to initial state
    function resetExercise() {
        stopTimer();
        discardSession();
        _pendingSaveDialog = false;
        _state = STATE_READY;
        _currentRep = 1;
        _currentSeries = 1;
        _timeRemaining = COUNTDOWN_TIME;
        Ui.requestUpdate();
    }

    //! Update the display
    //! @param dc The device context for drawing
    function onUpdate(dc as Gfx.Dc) as Void {
        // Show save dialog here, not from the timer callback — calling Ui.pushView()
        // from a timer callback corrupts the view stack and crashes on back-press.
        if (_pendingSaveDialog) {
            _pendingSaveDialog = false;
            showSaveConfirmation();
            return;
        }

        // Clear the screen
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        switch (_state) {
            case STATE_READY:
                drawReadyScreen(dc, centerX, centerY);
                break;
            case STATE_COUNTDOWN:
                drawCountdownScreen(dc, centerX, centerY);
                break;
            case STATE_CONTRACT:
                drawExerciseScreen(dc, centerX, centerY, true);
                break;
            case STATE_RELAX:
                drawExerciseScreen(dc, centerX, centerY, false);
                break;
            case STATE_COMPLETE:
                drawCompleteScreen(dc, centerX, centerY);
                break;
        }
    }

    //! Draw the ready/start screen
    private function drawReadyScreen(dc as Gfx.Dc, centerX as Lang.Number, centerY as Lang.Number) {
        var screenHeight = dc.getHeight();

        var hMedium = dc.getFontHeight(Gfx.FONT_MEDIUM);
        var hSmall = dc.getFontHeight(Gfx.FONT_SMALL);

        // --- TITLE ---
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var title1Y = (screenHeight * 0.15).toNumber();
        dc.drawText(centerX, title1Y, Gfx.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.AppTitle1), Gfx.TEXT_JUSTIFY_CENTER);

        var title2Y = title1Y + (hMedium * 0.8).toNumber();
        dc.drawText(centerX, title2Y, Gfx.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.AppTitle2), Gfx.TEXT_JUSTIFY_CENTER);

        // --- WORKOUT INFO ---
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);

        var repsY = (screenHeight * 0.45).toNumber();
        var repsText = _repsPerSeries + " reps x " + _numSeries + " series";
        dc.drawText(centerX, repsY, Gfx.FONT_SMALL, repsText, Gfx.TEXT_JUSTIFY_CENTER);

        var detailsY = repsY + hSmall;
        var detailsText = _contractTime + "s / " + _relaxTime + "s";
        dc.drawText(centerX, detailsY, Gfx.FONT_SMALL, detailsText, Gfx.TEXT_JUSTIFY_CENTER);

        // --- START PROMPT ---
        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        var promptY = (screenHeight * 0.75).toNumber();
        dc.drawText(centerX, promptY, Gfx.FONT_SMALL, WatchUi.loadResource(Rez.Strings.PressStart), Gfx.TEXT_JUSTIFY_CENTER);
    }

    //! Draw the initial countdown screen
    private function drawCountdownScreen(dc as Gfx.Dc, centerX as Lang.Number, centerY as Lang.Number) {
        var hNumber = dc.getFontHeight(Gfx.FONT_NUMBER_HOT);
        var hSmall = dc.getFontHeight(Gfx.FONT_SMALL);

        // --- GET READY text ---
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        var readyY = centerY - (hNumber / 2) - (hSmall * 0.9).toNumber();
        dc.drawText(centerX, readyY, Gfx.FONT_SMALL, WatchUi.loadResource(Rez.Strings.GetReady), Gfx.TEXT_JUSTIFY_CENTER);

        // --- Countdown number ---
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        var timerY = centerY - (hNumber / 2);
        dc.drawText(centerX, timerY, Gfx.FONT_NUMBER_HOT, _timeRemaining.toString(), Gfx.TEXT_JUSTIFY_CENTER);
    }

    //! Draw the exercise screen during contract/relax phases
    private function drawExerciseScreen(dc as Gfx.Dc, centerX as Lang.Number, centerY as Lang.Number, isContract as Lang.Boolean) {
        var width = dc.getWidth();

        // Arc parameters
        var penWidth = (width * 0.05).toNumber();
        if (penWidth < 4) { penWidth = 4; }
        var arcRadius = (width / 2) - (penWidth / 2) - 2;

        // Font metrics
        var hNumber = dc.getFontHeight(Gfx.FONT_NUMBER_HOT);
        var hSmall = dc.getFontHeight(Gfx.FONT_SMALL);

        // --- DRAW ARC ---
        dc.setPenWidth(penWidth);

        // Background arc
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.drawArc(centerX, centerY, arcRadius, Gfx.ARC_CLOCKWISE, 90, -270);

        // Progress arc
        var totalTime = isContract ? _contractTime : _relaxTime;
        var progress = (totalTime - _timeRemaining).toFloat() / totalTime.toFloat();
        var endAngle = 90 - (progress * 360).toNumber();

        dc.setColor(isContract ? Gfx.COLOR_RED : Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        if (progress > 0) {
            dc.drawArc(centerX, centerY, arcRadius, Gfx.ARC_CLOCKWISE, 90, endAngle);
        }

        // --- DRAW TEXT ---

        // Timer
        var timerY = centerY - (hNumber / 2);
        var timerColor = isContract ? Gfx.COLOR_RED : Gfx.COLOR_GREEN;
        dc.setColor(timerColor, Gfx.COLOR_TRANSPARENT);
        dc.drawText(centerX, timerY, Gfx.FONT_NUMBER_HOT, _timeRemaining.toString(), Gfx.TEXT_JUSTIFY_CENTER);

        // State label
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var stateText = isContract ? WatchUi.loadResource(Rez.Strings.Contract) : WatchUi.loadResource(Rez.Strings.Relax);
        var stateY = timerY - (hSmall * 0.9).toNumber();
        dc.drawText(centerX, stateY, Gfx.FONT_SMALL, stateText, Gfx.TEXT_JUSTIFY_CENTER);

        // Rep and series counter
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        var repText;
        if (_numSeries > 1) {
            repText = WatchUi.loadResource(Rez.Strings.Rep) + " " + _currentRep + "/" + _repsPerSeries + " - " + WatchUi.loadResource(Rez.Strings.Series) + " " + _currentSeries + "/" + _numSeries;
        } else {
            repText = WatchUi.loadResource(Rez.Strings.Rep) + " " + _currentRep + " " + WatchUi.loadResource(Rez.Strings.Of) + " " + _repsPerSeries;
        }
        var repY = timerY + hNumber;
        dc.drawText(centerX, repY, Gfx.FONT_SMALL, repText, Gfx.TEXT_JUSTIFY_CENTER);
    }

    //! Draw the completion screen
    private function drawCompleteScreen(dc as Gfx.Dc, centerX as Lang.Number, centerY as Lang.Number) {
        var height = dc.getHeight();
        var hMedium = dc.getFontHeight(Gfx.FONT_MEDIUM);

        // --- SUCCESS TITLE ---
        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        var yComplete = (height * 0.25).toNumber();
        dc.drawText(centerX, yComplete, Gfx.FONT_LARGE, WatchUi.loadResource(Rez.Strings.Complete), Gfx.TEXT_JUSTIFY_CENTER);

        // --- CENTRAL MESSAGE ---
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        var yGreatJob = centerY - (hMedium / 2);
        dc.drawText(centerX, yGreatJob, Gfx.FONT_MEDIUM, WatchUi.loadResource(Rez.Strings.GreatJob), Gfx.TEXT_JUSTIFY_CENTER);

        // --- INSTRUCTIONS ---
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        var yInstructions = (height * 0.75).toNumber();
        dc.drawText(centerX, yInstructions, Gfx.FONT_TINY, WatchUi.loadResource(Rez.Strings.Instructions), Gfx.TEXT_JUSTIFY_CENTER);
    }

    //! Check if exercise is in progress
    function isExerciseActive() as Lang.Boolean {
        return (_state == STATE_COUNTDOWN || _state == STATE_CONTRACT || _state == STATE_RELAX);
    }

    //! Get current state
    function getState() as Lang.Number {
        return _state;
    }
}
