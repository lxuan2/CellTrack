##### Instruction for running GUI and C# app to generate analyzed videos #####
########################
## Environment set up ##
########################
  Install MyAppInstaller_web.exe and K-Lite_Codec_Pack_1508_Basic.exe in the
folder /Environment Installer before you start.

  1. MyAppInstaller_web.exe: C# library of MATLAB code(CellTracking_GUI.m)
	 		     and MATLAB RunTime.
 	Note: In second step installation, Preferred Video Player is needed to
	      be Movies and TV app. See picture /Ready_to_Run/installNote.PNG.
  2. K-Lite_Codec_Pack_1508_Basic.exe: software bundle for playback of videos.

Note: If you don't use GUI to generate the videos, the second package is not 
    required to install.

#########################################
### Two Options to generate the video ###

#######################################
## Run the GUI to generate the video ##
#######################################

  Step 1: run cell.exe in the folder /Ready_to_Run/GUI.
  Step 2: select the C# app, CellTracking_App.exe, in the folder /Ready_to_Run
	  /C#App.
  Step 3: select the video file that you want to analyze in the file selector
	  in the video widget. (You can confirm your video by click the black
	  area to play.)
  Step 4: set the parameters in the control panel widget and click analyze 
	  button.
  Step 5: The window goes into Not Responding status. Just wait until it 
	  finishes all the processes. This may take longer than you think 
	  especially in the first time you run it.
          Note: The video file stores in the same folder of your original 
	       video file.
  Step 6: After it finishes, the statistics shows up in the log widget. Also 
	  the result video is automatically loaded.
#########################################
## Run the C#App to generate the video ##
#########################################

  Step 1: create a .txt file named tempPort.txt in folder /Ready_to_Run/C#App.
  Step 2: fill these variables line by line :

	videoPath
	videoName
	maxSize
	minSize
	isAreaEnable
	isEccentricityEnable
	isOrientationEnable
	
	An example tempPort.txt is included in folder /Ready_to_Run.
  Step 3: run CellTracking_App.exe. This may take longer than you think 
	  especially in the first time you run it.
          Note: The video file stores in the same folder of your original 
	       video file.
  Step 4: After it finishes, the statistics data is written into tempPort.txt.

##### End Instruction #####











