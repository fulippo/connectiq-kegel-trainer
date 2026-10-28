// Screenshot mode: a fixed screen for store captures. The shipping build keeps only the stub
// (monkey.jungle excludes "shotmode"); monkey-shot.jungle adds shot/ShotConfig.mc and keeps the
// real one. No timers, no recording, no vibration: the screen stays exactly as set.

using Toybox.Lang;

(:noshot)
module ShotMode {
    function initial(view as KegelTrainerView, delegate as KegelTrainerDelegate) as Lang.Array {
        return [view, delegate] as Lang.Array;
    }
}

(:shotmode)
module ShotMode {
    function initial(view as KegelTrainerView, delegate as KegelTrainerDelegate) as Lang.Array {
        view.shotState(SHOT_STATE, SHOT_REMAINING, SHOT_REP, SHOT_SERIES);
        return [view, delegate] as Lang.Array;
    }
}
