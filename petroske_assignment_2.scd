(
var additiveFunc;

var outputPath = "~/Desktop/petroske_assignment_2.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;
var synthDefLP, synthDefHP;
var freq, coeffs;
var allPass2ndOrderCoeffs;

var sinCosPanLaw;

sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};

allPass2ndOrderCoeffs = { arg centerFreq, bandwidth, sampleRate;
	var c = (tan(pi * bandwidth / sampleRate) - 1) / (tan(pi * bandwidth / sampleRate) + 1);
	var d = -1 * cos(2 * pi * centerFreq / sampleRate);

    [-1*c, d*(1-c), 1, -1*d*(1-c), c];
};


// 2nd-order bandpass/reject
// bpbr is negative: band pass, bpbr is positive: band reject
synthDefBPBR = CtkSynthDef.new(\filtAnalysisLP, { arg freq = 440.0, bandwidth, bpbr, probeBuf, analysisBuf;
    var probe, response;
    var tanFac, cFac, a0, a1, b1;

    #a0, a1, a2, b1, b2 = filtCoeffsFunc.value(freq, bandwidth, sampleRate);

    // play probe signal (impulse)
    probe = PlayBuf.ar(numChannels: 1, bufnum: probeBuf);

    // test filter with probe
    response = (SOS.ar(probe, a0, a1, a2, b1, b2) + (bpbr * probe)) * 0.5;

    // record into analysis buffer
    RecordBuf.ar(
        inputArray: response,
        bufnum: analysisBuf,
        loop: 0
    );
});

// analyse BPBR
synthDefLP.note(starttime: 0.2, duration: ~signalDur)
.freq_(freq)
.probeBuf_(~probeBuffer)
.analysisBuf_(~analysisBuffer)
.bpbr_(-1)
.play;


// 3) Plot analysis (via FFT)
//
// NOTE: FFT returns linear frequency
(
var wait = 0.01, defer = 0.1;

~analysisBuffer.getToFloatArray(
    wait: wait,
    action: {arg response;
        {
            var fftResponse, fftMagnitude;

            // FFT analysis here!
            fftResponse = fft(
                response.as(Signal),
                Signal.newClear(~size),
                Signal.fftCosTable(~size)
            );

            // find (& trim magnitude)
            fftMagnitude = fftResponse.magnitude;
            fftMagnitude = fftMagnitude.copyFromStart((~size/2).asInteger);

            // plot magnitude spectrum of the kernel
            fftMagnitude.ampdb.plot(
                name: "Filter Magnitude Response",
                minval: ~plotDbMin,
                maxval: ~plotDbMax
            )

        }.defer(defer);
        "done".postln;
});
)



// score.write(
//     path: outputPath.standardizePath,
//     sampleRate: sampleRate,
//     headerFormat: headerFormat,
//     sampleFormat: sampleFormat,
//     options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
// );
)
