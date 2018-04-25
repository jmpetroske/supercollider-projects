s = Server.local.boot;
s.quit;

SCDoc.renderAll

"SC_JACK_DEFAULT_INPUTS".setenv("system:capture_1");
"SC_JACK_DEFAULT_OUTPUTS".setenv("system");

Quarks.gui

Platform.userExtensionDir

(Platform.userExtensionDir +/+ "DXARTS/HelpSource/Tutorials/DXARTS-462").mkdir;
(Platform.userExtensionDir +/+ "DXARTS/HelpSource/Assignments/DXARTS-462").mkdir;

(
var additiveFunc;

var outputPath = "~/Desktop/petroske_final.wav";
var headerFormat = "WAV";
var sampleFormat = "int24";
var numOutputChannels = 2;
var sampleRate = 44100;

var sinCosPanLaw;

sinCosPanLaw = { arg angleInDegrees = 0;
    var angleInRadians;
    var theta;

    angleInRadians = -angleInDegrees/180*pi;

    theta = pi/4 - angleInRadians;

    [theta.cos, theta.sin]
};


score.write(
    path: outputPath.standardizePath,
    sampleRate: sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

