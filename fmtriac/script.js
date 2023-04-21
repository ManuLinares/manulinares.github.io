/*function padLeadingZeros(num, size) {
	var s = num+"";
	while (s.length < size) s = "0" + s;
	return s;
}


var randNumer = padLeadingZeros(Math.floor(Math.random() * 13 + 1), 2);
$('body').css('background', 'rgba(0, 0, 0, 0) url(https://raw.githubusercontent.com/ManuLinares/stuff/main/img/'+randNumer+'.jpeg) no-repeat scroll 0% 0% / cover');;
*/

$(function() {

	var audio = $("audio")[0];
	var tmpDuration = Infinity;

	// Any first click interaction on the page, starts to play audio.
	var userinteraction = 0
	document.addEventListener('click',()=>{
	 	if(userinteraction) return;
	 	userinteraction++;
	 	if (audio.paused === true) {
			audio.play();
			$('#btn-play-pause').children('svg').replaceWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><!-- Font Awesome Free 5.15.4 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) --><path d="M144 479H48c-26.5 0-48-21.5-48-48V79c0-26.5 21.5-48 48-48h96c26.5 0 48 21.5 48 48v352c0 26.5-21.5 48-48 48zm304-48V79c0-26.5-21.5-48-48-48h-96c-26.5 0-48 21.5-48 48v352c0 26.5 21.5 48 48 48h96c26.5 0 48-21.5 48-48z"/></svg>')
		}			 

	})

	$('#btn-play-pause').on('click', function() {
		//Play/pause the track
		if (audio.paused == false) {
			audio.pause();
			$(this).children('svg').replaceWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path fill=white d="M424.4 214.7L72.4 6.6C43.8-10.3 0 6.1 0 47.9V464c0 37.5 40.7 60.1 72.4 41.3l352-208c31.4-18.5 31.5-64.1 0-82.6z"/></svg>')
		} else {
			audio.play();
			$(this).children('svg').replaceWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><!-- Font Awesome Free 5.15.4 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) --><path d="M144 479H48c-26.5 0-48-21.5-48-48V79c0-26.5 21.5-48 48-48h96c26.5 0 48 21.5 48 48v352c0 26.5-21.5 48-48 48zm304-48V79c0-26.5-21.5-48-48-48h-96c-26.5 0-48 21.5-48 48v352c0 26.5 21.5 48 48 48h96c26.5 0 48-21.5 48-48z"/></svg>')
		}
	});

	$('#btn-stop').on('click', function() {
		//Stop the track
		audio.pause();
		audio.autoplay = false;
		audio.src = audio.currentSrc;
		audio.currentTime = 0;
		$('#btn-play-pause').children('svg').replaceWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path fill=white d="M424.4 214.7L72.4 6.6C43.8-10.3 0 6.1 0 47.9V464c0 37.5 40.7 60.1 72.4 41.3l352-208c31.4-18.5 31.5-64.1 0-82.6z"/></svg>')
	});
	
	$('#btn-mute').on('click', function() {
		//Mutes/unmutes the sound
		if(audio.volume != 0) {
			audio.volume = 0;
			$(this).children('svg').replaceWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 512"><path fill=white d="M215 71l-89 89H24a24 24 0 0 0-24 24v144a24 24 0 0 0 24 24h102.06L215 441c15 15 41 4.47 41-17V88c0-21.47-26-32-41-17z"/></svg>');
		} else {
			audio.volume = 1;
			$(this).children('svg').replaceWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 576 512"><path fill=white d="M215.03 71.05L126.06 160H24c-13.26 0-24 10.74-24 24v144c0 13.25 10.74 24 24 24h102.06l88.97 88.95c15.03 15.03 40.97 4.47 40.97-16.97V88.02c0-21.46-25.96-31.98-40.97-16.97zm233.32-51.08c-11.17-7.33-26.18-4.24-33.51 6.95-7.34 11.17-4.22 26.18 6.95 33.51 66.27 43.49 105.82 116.6 105.82 195.58 0 78.98-39.55 152.09-105.82 195.58-11.17 7.32-14.29 22.34-6.95 33.5 7.04 10.71 21.93 14.56 33.51 6.95C528.27 439.58 576 351.33 576 256S528.27 72.43 448.35 19.97zM480 256c0-63.53-32.06-121.94-85.77-156.24-11.19-7.14-26.03-3.82-33.12 7.46s-3.78 26.21 7.41 33.36C408.27 165.97 432 209.11 432 256s-23.73 90.03-63.48 115.42c-11.19 7.14-14.5 22.07-7.41 33.36 6.51 10.36 21.12 15.14 33.12 7.46C447.94 377.94 480 319.54 480 256zm-141.77-76.87c-11.58-6.33-26.19-2.16-32.61 9.45-6.39 11.61-2.16 26.2 9.45 32.61C327.98 228.28 336 241.63 336 256c0 14.38-8.02 27.72-20.92 34.81-11.61 6.41-15.84 21-9.45 32.61 6.43 11.66 21.05 15.8 32.61 9.45 28.23-15.55 45.77-45 45.77-76.88s-17.54-61.32-45.78-76.86z"/></svg>');
		}
	});

	function updateProgress() {
		//Updates the progress bar
		var progress = document.getElementById("progress");
		var value = 0;
		if (audio.duration === Infinity) {
			tmpDuration = audio.currentTime;
		} else {
			tmpDuration = audio.duration;
		}
		if (audio.currentTime > 0) {
			value = Math.floor((100 / tmpDuration) * audio.currentTime);
		}
		progress.style.width = value + "%";

		if (audio.paused == false) {
			$('#btn-play-pause').children('svg').replaceWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><!-- Font Awesome Free 5.15.4 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free (Icons: CC BY 4.0, Fonts: SIL OFL 1.1, Code: MIT License) --><path d="M144 479H48c-26.5 0-48-21.5-48-48V79c0-26.5 21.5-48 48-48h96c26.5 0 48 21.5 48 48v352c0 26.5-21.5 48-48 48zm304-48V79c0-26.5-21.5-48-48-48h-96c-26.5 0-48 21.5-48 48v352c0 26.5 21.5 48 48 48h96c26.5 0 48-21.5 48-48z"/></svg>')
		}		
	}

	
	function isMobileDoStuff()
	{
		// Detect mobile
		let details = navigator.userAgent;
		let regexp = /android|iphone|kindle|ipad/i;
		let isMobileDevice = regexp.test(details);
		if (!isMobileDevice) {
			$('#whatsapp_link').attr("href", "https://web.whatsapp.com/send?phone=543544654243&text=Hola, quisiera contactarme!");
		}	
	}



	var canvas = document.getElementById("canvas");
	canvas.width = window.innerWidth;
	canvas.height = window.innerHeight;
	var ctx = canvas.getContext("2d");
	var requestAnimationFrameId;

	var AudioContext = (window.AudioContext || window.webkitAudioContext);
	var source, analyser;


	function visualizerStart()
	{
		
		// Set up routes
		const audioCtx = new(AudioContext);
		if (!analyser) 
		{ 
			analyser = audioCtx.createAnalyser();
			analyser.fftSize = 256;
		};
		if (!source) 
		{ 
			source = audioCtx.createMediaElementSource(audio);
			source.connect(audioCtx.destination);
		};

		source.connect(analyser);

		  
		analyser.fftSize = 256;
	  
		var bufferLength = analyser.frequencyBinCount -20;
		var dataArray = new Uint8Array(bufferLength);
		analyser.getByteFrequencyData(dataArray);
	
		var WIDTH = canvas.width;
		var HEIGHT = canvas.height;

		var barWidth = ((WIDTH / bufferLength)  + 0.5) << 0;
		var barHeight;


		function drawVisualization(ctx){		
			//ctx.fillStyle = "rgba(0, 0, 0, 0.1)";
			ctx.clearRect(0, 0, WIDTH, HEIGHT);
	  
			let x = 0;

			for (var i = 1; i <= bufferLength; i++) {
			  barHeight = dataArray[i];
			  
			  var r = ((barHeight + (25 * (i/bufferLength))) + 0.5) << 0;
			  var g = (( 250 * (i/bufferLength)) + 0.5) << 0;
			  var b = 50;
	  
			  ctx.fillStyle = "rgb(" + r + "," + g + "," + b + ")";
			  ctx.fillRect(x, (HEIGHT - barHeight), barWidth, barHeight);
	  
			  x += barWidth + 1;
			}
		}

		function renderFrame() {
			analyser.getByteFrequencyData(dataArray);
			drawVisualization(ctx);
			requestAnimationFrameId = requestAnimationFrame(renderFrame);
		}

		if (audio.paused === false) renderFrame();
		
	};

	function visualizerStop(){
		ctx.fillStyle = "rgba(0, 0, 0, 1)";;
		ctx.clearRect(0, 0, canvas.width, canvas.height);
		cancelAnimationFrame(requestAnimationFrameId);
		
	}

	//Audio event listeners
	audio.addEventListener("timeupdate", updateProgress, false);
	audio.addEventListener("play", visualizerStart);
	audio.addEventListener("pause", visualizerStop);

	isMobileDoStuff();


});