/*
This is an example startup file. You can load it from your startup file
(to be found in Platform.userAppSupportDir +/+ "startup.scd")
*/

(
s.reboot { // server options are only updated on reboot
    // configure the sound server: here you could add hardware specific options
    // see http://doc.sccode.org/Classes/ServerOptions.html
    s.options.numBuffers = 1024 * 256; // increase this if you need to load more samples
    s.options.memSize = 8192 * 32; // increase this if you get "alloc failed" messages
    s.options.numWireBufs = 64; // increase this if you get "exceeded number of interconnect buffers" messages
    s.options.maxNodes = 1024 * 32; // increase this if you are getting drop outs and the message "too many nodes"
    s.options.numOutputBusChannels = 2; // set this to your hardware output channel size, if necessary
    s.options.numInputBusChannels = 2; // set this to your hardware output channel size, if necessary
    // boot the server and start SuperDirt
    s.waitForBoot {
        ~dirt = SuperDirt(2, s); // two output channels, increase if you want to pan across more channels
        ~dirt.loadSoundFiles;     // load samples (path containing a wildcard can be passed in)
        ~dirt.loadSoundFiles("/home/hugo/repos/tidal-scratchpad/samples-extra/*");
        ~dirt.loadSoundFiles("/home/hugo/repos/tidal-scratchpad/VintageDrums/*");
        ~dirt.loadSoundFiles("/home/hugo/repos/tidal-scratchpad/extra/*");
        // for example: ~dirt.loadSoundFiles("/Users/myUserName/Dirt/samples/*");
        // s.sync; // optionally: wait for samples to be read
        ~dirt.start(57120, 0 ! 12);     // start listening on port 57120, create two busses each sending audio to channel 0

        // optional, needed for convenient access from sclang:
        (
            ~d1 = ~dirt.orbits[0]; ~d2 = ~dirt.orbits[1]; ~d3 = ~dirt.orbits[2];
            ~d4 = ~dirt.orbits[3]; ~d5 = ~dirt.orbits[4]; ~d6 = ~dirt.orbits[5];
            ~d7 = ~dirt.orbits[6]; ~d8 = ~dirt.orbits[7]; ~d9 = ~dirt.orbits[8];
            ~d10 = ~dirt.orbits[9]; ~d11 = ~dirt.orbits[10]; ~d12 = ~dirt.orbits[11];

        );

        // synths
        (
            "/home/hugo/.config/SuperCollider/synths/loadAll.scd".load();
        );

        // generate a list of all audio samples which I use as input for neovim to search
        // them easily.
        (
          File.use("~/.config/SuperCollider/dirt_samples.txt".standardizePath, "w", { |f|
            ~dirt.buffers.keysValuesDo { |key, value|
              // Check if the value is an Array (should always be the case AFAIK)
              if (value.isArray) {
                value.size.do { |i|
                  // Assuming 'value' contains buffer indices
                  var buffer = value[i];
                  var duration = 0;
                  var sampleName = key ++ ":" ++ i;
                  if (buffer.notNil) {
                      duration = buffer.duration;
                  };
                  duration = (duration * 100).asInteger / 100.0;

                  f.write(sampleName.padRight(20, " ") ++ duration.asString ++ "s\n");
                };
              };
            };

            // Add the synthesisers to the sample index
            SynthDescLib.global.synthDescs.keysDo({ |key|
              f.write(key.asString.padRight(20, " ") ++ "synth\n");
            });
          });
        );
    };

    s.latency = 0.3; // increase this if you get "late" messages
};
);
