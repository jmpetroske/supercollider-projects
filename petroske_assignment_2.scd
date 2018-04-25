(
var size = 2.pow(13); // we're using the FFT, so should be a power of 2
var plotDbMin = -24.0;
var plotDbMax = 6.0;
var signalDur;
var probeSignal;
var probeBuffer;
var analysisBuffer;

var wait = 5, defer = 5;


var additiveFunc;

var outputPath = "~/Desktop/petroske_assignment_2.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;
var synthDefBPBR;
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
	var c = (tan(pi * bandwidth / s.sampleRate) - 1) / (tan(pi * bandwidth / s.sampleRate) + 1);
	var d = -1 * cos(2 * pi * centerFreq / s.sampleRate);

    [-1*c, d*(1-c), 1, -1*d*(1-c), c];
};

// 2nd-order bandpass/reject
// bpbr is negative: band pass, bpbr is positive: band reject
synthDefBPBR = CtkSynthDef.new(\filtAnalysisLP, { arg freq = 440.0, bandwidth, bpbr, probeBuf, analysisBuf;
    var probe, response;
    var tanFac, cFac, a0, a1, a2, b1, b2;

    #a0, a1, a2, b1, b2 = allPass2ndOrderCoeffs.value(freq, bandwidth, sampleRate);

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


size = 2.pow(13); // we're using the FFT, so should be a power of 2

// plot paramaters
plotDbMin = -24.0;
plotDbMax = 6.0;

// calcs
signalDur = size / (s.sampleRate); // duration to run synth...

// create probe signal, an impulse
probeSignal = Signal.newClear(size);
probeSignal.put((size/2).asInteger, 1.0);

// load probe signal into a buffer
probeBuffer = Buffer.loadCollection(
    server: s,
    collection: probeSignal
);

// empty analysis buffer - to record filter response
analysisBuffer = Buffer.alloc(server: s, numFrames: size);

// analyse BPBR
synthDefBPBR.note(starttime: 0.2, duration: signalDur)
.freq_(freq)
.probeBuf_(probeBuffer)
.analysisBuf_(analysisBuffer)
.bpbr_(-1)
.play;


analysisBuffer.getToFloatArray(
    wait: wait,
    action: {arg response;
        {
            var fftResponse, fftMagnitude;

            // FFT analysis here!
            fftResponse = fft(
                response.as(Signal),
                Signal.newClear(size),
                Signal.fftCosTable(size)
            );

            // find (& trim magnitude)
            fftMagnitude = fftResponse.magnitude;
            fftMagnitude = fftMagnitude.copyFromStart((size/2).asInteger);

            // plot magnitude spectrum of the kernel
            fftMagnitude.ampdb.plot(
                name: "Filter Magnitude Response",
                minval: plotDbMin,
                maxval: plotDbMax
            )

        }.defer(defer);
        "done".postln;
});



// score.write(
//     path: outputPath.standardizePath,
//     sampleRate: sampleRate,
//     headerFormat: headerFormat,
//     sampleFormat: sampleFormat,
//     options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
// );
)
