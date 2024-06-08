(
s.options.outDevice_("BlackHole 128ch"); //MODIFY WITH YOUR VERSION

s.waitForBoot({

	var win, soundFileView, buffer, openButton, startButton, soundFile;
	var startPosLo, startPosHi, text, subwin;
	var azimuthSlider, elevationSlider, routine;
	var envGui, textEnv, textEnvPitch, envPitchGui;
	var elevLo = 0, elevHi = 0, azLo = -pi/2, azHi = pi/2;
	var distSlider, distLo = 1, distHi = 5;
	var waitLo = 0.5, waitHi = 1, ampLo = 0.5, ampHi = 0.5;
	var filtLo = 20, filtHi = 20000, pbHi = 1, pbLo = 1;
	var ambiOrder = 3;
	var env1 = 0.1, env2 = 0.4, env3 = 0.6, env4 = 0.2, env5 = 0.1;
	var envTime1 = 0.0, envTime2 = 0.4, envTime3 = 0.6, envTime4 = 0.0;
	var durationLo = 0.5, durationHi = 1;
	var motion = 1;
	var envPitch1 = 0, envPitch2 = 0, envPitch3 = 0, envPitchTime1 = 0.5, envPitchTime2 = 0.5;
	var curvePitch = 5, curveAmp = 5;
	Window.closeAll;
	Buffer.freeAll;


	win = Window.new("Ambisonics Spatialiser", Rect(100, 100, 800, 1000)).alwaysOnTop_(true).front;
	//~file = FileDialogxp
	win.background = Color.grey(0.1, 0.9);
	win.onClose = {s.freeAll};

	// Sound File View
	soundFileView = SoundFileView.new(win, Rect(30, 700, 740, 200)).gridColor_(Color.gray(0.3));

	openButton = Button(win, Rect(680, 10, 100, 100)).states_([
		["Open Soundfile"]
	])
	.action_({
		Dialog.openPanel(
			{
				|path|
				path.postln;
				soundFile = SoundFile.new;
				soundFile.openRead(path);
				// Load sound into buffer
				buffer = Buffer.readChannel(s, path, channels:[0]);
				// Display sound on View
				buffer.normalize;
				soundFileView.soundfile_(soundFile);
				soundFileView.read(0, soundFile.numFrames);
				startPosLo = 0;
				startPosHi = soundFile.numFrames;
				soundFileView.timeCursorOn = true;
				soundFileView.timeCursorColor = Color.red;
				soundFileView.timeCursorPosition = 0;
				soundFileView.gridOn = true;
				soundFileView.gridResolution = 0.2;
			},
			{
				"Cancelled".postln;
			}
		);

	});

	soundFileView.mouseUpAction = {arg view;
		var loFrames, hiFrames, loSlider, hiSlider;
		loFrames = view.selection(0)[0];
		hiFrames = view.selection(0)[1] + loFrames;
		[loFrames, hiFrames, view].postln;
		if(startButton.value == 1,
			{
				startPosLo = loFrames;
				startPosHi = hiFrames;
			},
			{
				startPosLo = loFrames; //keep these saved so I can use them to set the synth later
				startPosHi = hiFrames;
			}
		);
	};

	startButton = Button(win, Rect(560, 10, 100, 100))
	.states_([
		["Start", Color.white, Color.red],
		["Stop", Color.white, Color.black]
	])
	.action_({
		|button|
		if(button.value == 1,
			{
				routine.reset;
				routine.play;

			},
			{routine.stop;}
		);

	});

	text = StaticText(win, Rect(20, 10, 500, 100))
	.string_("This is an Ambisonics spatialiser that sends out B-format audio at the desired order.  So take into account the number of channels and the audio output (e.g.  BlackHole 128).  Azimuth and elevation is sampled randomly between max and min value specified in the slider.")
	.align_(\center);
	text.stringColor_(Color.white);


	subwin = CompositeView.new(win, Rect(20, 110, 760, 350)).background_(Color.red(0.4));
	subwin.decorator = FlowLayout(Rect(20, 110, 800, 450), 20@20, 10@10);
	EZRanger.new(
		subwin,
		80@320,
		"Playback Rate",
		ControlSpec(
			-2,
			2,
			'lin',
			(1.midiratio)/100
		),
		{|value|
			if(startButton.value==1, {
				pbHi = value.lo;
				pbLo = value.hi;
			})
		},
		[1, 1],
		true,
		labelHeight:30,
		layout:'vert'

	).setColors(stringColor: Color.white);
	EZRanger.new(
		subwin,
		80@320,
		"Filter cutoff",
		ControlSpec(
			20,
			20000,
			'exp',
			1.0
		),
		{|value|
			if(startButton.value==1, {
				filtLo = value.lo;
				filtHi = value.hi;
			})
		},
		[20, 20000],
		true,
		labelHeight:30,
		layout:'vert'

	).setColors(stringColor: Color.white);

	EZSlider.new(
		subwin,
		80@320,
		"Motion",
		ControlSpec(
			1,
			-1,
			'lin',
			0.001
		),
		{|ez|
			if(startButton.value==1, {
				motion = ez.value;
			})
		},
		1,
		true,
		labelHeight:30,
		layout:'vert'

	).setColors(stringColor: Color.white);
	EZRanger.new(
		subwin,
		80@320,
		"Amplitude",
		ControlSpec(
			0.0,
			1.0,
			'lin',
			0.001
		),
		{|value|
			if(startButton.value==1, {
				ampLo = value.lo;
				ampHi = value.hi;
			})
		},
		[0.5, 0.5],
		true,
		labelHeight:30,
		layout:'vert'

	).setColors(stringColor: Color.white);
	EZRanger.new(
		subwin,
		80@320,
		"Wait time range",
		ControlSpec(
			0.01,
			5,
			'exp',
			0.01,
			units: "WaitTime"
		),
		{|value|
			if(startButton.value==1, {
				waitLo = value.lo;
				waitHi = value.hi;
			})
		},
		[0.5, 1],
		true,
		labelHeight:30,
		layout:'vert'

	).setColors(stringColor: Color.white);

	EZRanger.new(
		subwin,
		80@320,
		"Splice duration",
		ControlSpec(
			0.01,
			5,
			'exp',
			0.01,
		),
		{|value|
			if(startButton.value==1, {
				durationLo = value.lo;
				durationHi = value.hi;
			})
		},
		[0.5, 1],
		true,
		labelHeight:30,
		layout:'vert'

	).setColors(stringColor: Color.white);

	//ENVELOPE

	textEnv = StaticText(win, Rect(630, 120, 100, 40))
	.string_("Amp Envelope")
	.align_(\center);
	textEnv.stringColor_(Color.white);

	envGui = EnvelopeView(win, Rect(580, 160, 190, 80))
	.drawLines_(true)
	.drawRects_(true)
	.resize_(3)
	.value_([[0, 0.2, 0.5, 0.75, 1], [0.0, 0.4, 0.6, 0.2, 0.0]])
	.keepHorizontalOrder_(true)
	.action_({
		|array|
		env1 = array.value[1][0];
		env2 = array.value[1][1];
		env3 = array.value[1][2];
		env4 = array.value[1][3];
		env5 = array.value[1][4];
		envTime1 = (array.value[0][1] - array.value[0][0]).abs;
		envTime2 = (array.value[0][2] - array.value[0][1]).abs;
		envTime3 = (array.value[0][3] - array.value[0][2]).abs;
		envTime4 = (array.value[0][4] - array.value[0][3]).abs;
	});


	textEnvPitch = StaticText(win, Rect(630, 240, 100, 40))
	.string_("Pitch Envelope")
	.align_(\center);
	textEnvPitch.stringColor_(Color.white);

	envPitchGui = EnvelopeView(win, Rect(580, 280, 190, 80))
	.drawLines_(true)
	.drawRects_(true)
	.resize_(3)
	.value_([[0, 0.5, 1], [0.0, 0.0, 0.0]])
	.keepHorizontalOrder_(true)
	.action_({
		|array|
		envPitch1 = array.value[1][0];
		envPitch2 = array.value[1][1];
		envPitch3 = array.value[1][2];
		envPitchTime1 = (array.value[0][1] - array.value[0][0]).abs;
		envPitchTime2 = (array.value[0][2] - array.value[0][1]).abs;
	});


	//Ambisonics order

	EZPopUpMenu.new(win, Rect(580, 370, 120, 60),
		"Ambisonics Order",
		[
			\First -> { |order|
				ambiOrder = 1;
			},
			\Second -> { |order|
				ambiOrder = 2;
			},
			\Third -> { |order|
				ambiOrder = 3;
			},
			\Fourth -> { |order|
				ambiOrder = 4;
			},
			\Fifth -> { |order|
				ambiOrder = 5;
			},
		],
		initVal: 2,
		initAction: true,
		layout:'vert'
	).setColors(stringColor: Color.white);



	EZSlider.new(
		win,
		Rect(708, 370, 32, 80),
		nil,
		ControlSpec(
			-15,
			15,
			'lin',
			1
		),
		{|ez|
			if(startButton.value==1, {
				curveAmp = ez.value;
			})
		},
		1,
		true,
		layout:'vert'

	).setColors(stringColor: Color.white);

	EZSlider.new(
		win,
		Rect(745, 370, 32, 80),
		nil,
		ControlSpec(
			-15,
			15,
			'lin',
			1
		),
		{|ez|
			if(startButton.value==1, {
				curvePitch = ez.value;
			})
		},
		1,
		true,
		layout:'vert'

	).setColors(stringColor: Color.white);


	azimuthSlider = EZRanger(
		win,
		Rect(20, 500, 740, 70),
		"Azimuth",
		ControlSpec(
			pi,
			-pi,
			'lin',
			0.0001,
			0,
			"Radiant"
		),
		{
			|value|
			if(startButton.value==1, {
				azLo = value.lo;
				azHi = value.hi;
			})
		},
		[pi/2, -pi/2],
		true
	)
	.setColors(stringColor: Color.white);

	distSlider = EZRanger(
		win,
		Rect(20, 610, 740, 30),
		"Distance",
		ControlSpec(
			1,
			20,
			'exp',
			0.0001,
			0,
			"Meters"
		),
		{
			|value|
			if(startButton.value==1, {
				distLo = value.lo;
				distHi = value.hi;
			})
		},
		[1, 20],
		true
	)
	.setColors(stringColor: Color.white);

	elevationSlider = EZRanger(
		win,
		Rect(20, 660, 740, 30),
		"Elevation",
		ControlSpec(
			-pi/2,
			pi/2,
			'lin',
			0.0001,
			0,
			"Radiant"
		),
		{
			|value|
			if(startButton.value==1, {
				elevLo = value.lo;
				elevHi = value.hi;
			})
		},
		[0, 0],
		true
	)
	.setColors(stringColor: Color.white);

	routine = Routine({
		var azi, dur, elev, dist;
		inf.do{
			azi = rrand(azLo, azHi);
			dur = rrand(durationLo, durationHi);
			elev = rrand(elevLo, elevHi);
			dist = rrand(distHi, distLo);
			{
				HOAEncoder.ar(
					ambiOrder,
					LPF.ar(
						HPF.ar(
							PlayBuf.ar(
								1,
								buffer,
								rrand(pbLo, pbHi)
								+
								EnvGen.kr(
									Env.new(
										[envPitch1, envPitch2, envPitch3],
										[envPitchTime1, envPitchTime2],
										curvePitch
									),
									1,
									timeScale:dur,
									doneAction: 0

								),
								1,
								rrand(startPosLo, startPosHi),
								1,
								0
							)
							* rrand(ampLo, ampHi)
							* EnvGen.kr(
								Env.new(
									[env1, env2, env3, env4, env5],
									[envTime1, envTime2, envTime3, envTime4],
									curveAmp
								),
								1,
								timeScale:dur,
								doneAction:2
							),
							filtLo
						),
						filtHi
					),
					Line.kr(azi, azi * motion, dur),
					Line.kr(elev, elev * motion, dur),
					0,
					1,
					dist
				)
			}.play;
			rrand(waitLo, waitHi).wait;
		}
	});
})
)
