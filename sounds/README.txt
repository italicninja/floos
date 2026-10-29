Floos sound alerts
==================

This folder is empty on purpose.

Floos ships no audio. Drop your own .wav files in here and they become
selectable in the config (Sound tab) and via /floos sound.

After adding or removing files, press "Rescan Folder" in the config, or run
/floos sound - the folder is read at load and on rescan, not every frame.


Rules of thumb
--------------

  * .wav only. That is an Ashita limit, not a Floos one:
    ashita.misc.play_sound plays wav files. Convert mp3 first.

  * Keep them short. These fire mid-swing, and a four-second fanfare on
    every 0.1 skill-up stops being fun quickly.

  * Nothing is set by default. Every event starts on "None", so the addon
    stays silent until you choose a file. A default pointing at a filename
    would be a broken default for everyone who does not have that file.


Where to get sounds
-------------------

Anywhere you like - they are just wav files. If you want a ready-made set,
the Yield addon ships a large pack:

    https://github.com/Sjshovan/Yield

Copy the ones you want out of its sounds/ folder into this one.

Please note those files are ripped game audio (Square Enix, Nintendo and
others). They are fine for your own use on your own machine. They are not
ours to redistribute, which is why Floos ships none of them, and why you
should not add them to a fork you publish either.
