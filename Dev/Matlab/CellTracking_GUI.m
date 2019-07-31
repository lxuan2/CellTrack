%This code identifies the moving microsopic cells in a real-time video
%input data and continuously tracks the movement of these detected cells in
%the video. The code can also evaluate the various geometric properties of
%the detected cells such as their area, eccentricity and orientation.

%At the end of processing the entire video, the code determines the total
%number of moving cells that were present in the video and the percentage
%of the cells that stopped moving on application of voltage.


function [totalcells_GT, totalcells, stoppedcells_GT, stoppedcells, stoppedpercent_GT, stopped_percent,tracking_accuracy, stoppedcell_accuracy, output_filename] = CellTracking_GUI(videoPath, videoName, maxSize, minSize, areaBool, eccentricityBool, orientationBool)



close all;

% The input video file name needs to be set here by the user

cd (sprintf('%s',videoPath));

input_filename=videoName;


%The following lines set default values to some of the
%hyperparameters. These values have been determined after experimental
%tuning.

if strcmp(input_filename,'cyto_data1.mp4')
    
output_filename='output_cyto_data1.avi';
min_cellarea=90;
max_cellarea=280;
totalcells_Groundtruth=16;
stoppedcells_Groundtruth=10;
cost_nonassignment=400;
invisibilityduration=30;
num_stationaryframes=5;


elseif strcmp(input_filename,'AK_FFL_UVA_6.28.19_video1.mp4') 
    
output_filename='output_AK_FFL_UVA_6.28.19_video1.avi';
min_cellarea=270;
max_cellarea=750;
totalcells_Groundtruth=34;
stoppedcells_Groundtruth=20;
cost_nonassignment=800;
invisibilityduration=35;
num_stationaryframes=5;


elseif strcmp(input_filename,'GK_FFL_E_mix_UVA_6.5.19_trimmed.mp4') 
    
output_filename='output_GK_FFL_E_mix_UVA_6.5.19_trimmed.avi';
min_cellarea=200;
max_cellarea=700;
totalcells_Groundtruth=24;
stoppedcells_Groundtruth=12;
cost_nonassignment=550;
invisibilityduration=40;
num_stationaryframes=5;


elseif strcmp(input_filename,'AK_FFL_UVA_6.28.19_video2.mp4') 
    
output_filename='output_AK_FFL_UVA_6.28.19_video2.avi';
min_cellarea=270;
max_cellarea=650;
totalcells_Groundtruth=12;
stoppedcells_Groundtruth=6;
cost_nonassignment=400;
invisibilityduration=50;
num_stationaryframes=5;


elseif strcmp(input_filename,'original_trimmed.mp4')
    
output_filename='output_original_trimmed.avi';
min_cellarea=18;
max_cellarea=120;
totalcells_Groundtruth=33;
stoppedcells_Groundtruth=5;
cost_nonassignment=600;
invisibilityduration=90;
num_stationaryframes=4;

end

if maxSize ~= 0 || minSize ~= 0
    min_cellarea=minSize;
    max_cellarea=maxSize;
end


% The user can select the geometric properties such as Area, Eccentricity and
%orientation which need to be displayed by setting the following variables
%in lines 96-98 to 1.

Area_label=areaBool;
Eccentricity_label=eccentricityBool;
Orientation_label =orientationBool;


obj = setupSystemObjects();

tracks = initializeTracks(); % Create an empty array of tracks.

nextId = 1; % ID of the next track
frame_num=0;

v = VideoWriter(output_filename,'Uncompressed AVI');
open(v);


stationary_frame=zeros(100);
idx=1;
resultarray=[];
oldpos=zeros(100,2);
newpos=ones(100,2);



% Detect moving objects, and track them across video frames.
while ~isDone(obj.reader)
    frame = readFrame();
 


    frame_num=frame_num+1;
    [areas,centroids, bboxes, mask, majoraxis, minoraxis, orientation,eccentricity] = detectObjects(frame,frame_num);
    predictNewLocationsOfTracks();
    [assignments, unassignedTracks, unassignedDetections] = ...
        detectionToTrackAssignment();
    
    updateAssignedTracks();
    updateUnassignedTracks();
    deleteLostTracks();
    createNewTracks();
    
    displayTrackingResults();
    
 
end

   res=unique(resultarray);
   stoppedcellcount=size(res);
   
   
   %Displaying the results to the user
   
  disp('Total number of cells present (Ground Truth)');
  totalcells_GT=totalcells_Groundtruth;
  disp(totalcells_GT);
  
  
  disp('Total number of cells detected by tracking');
  totalcells=nextId;
  disp(totalcells);
  
  disp('Number of cells that stopped (Ground Truth)');
  stoppedcells_GT=stoppedcells_Groundtruth;
  disp(stoppedcells_GT);
  
   disp('Number of cells that stopped');
   stoppedcells=stoppedcellcount(2);
   disp(stoppedcells);
   
   disp('Percentage of cells that stopped (Ground Truth)');
   stopped_percent_groundtruth=stoppedcells_Groundtruth/totalcells_Groundtruth *100;
   disp(stopped_percent_groundtruth);
   stoppedpercent_GT=stopped_percent_groundtruth;
   
   disp('Percentage of cells that stopped');
   stopped_percent=stoppedcellcount(2)/nextId *100;
   disp(stopped_percent);
   
   disp('Accuracy in tracking cells :');
   tracking_accuracy= (nextId/totalcells_Groundtruth) *100;
   disp(tracking_accuracy);
  
   disp('Accuracy in tracking stopped cells :');
   stoppedcell_accuracy=(stoppedcellcount(2)/stoppedcells_Groundtruth) *100 ;
   disp(stoppedcell_accuracy);
   
  %Close the video writer 
   close(v);

%% Create System Objects

    function obj = setupSystemObjects()
       
        % Create a video file reader.
        obj.reader = vision.VideoFileReader(input_filename);
        
               
        % The foreground detector is used to segment moving objects from
        % the background. It outputs a binary mask, where the pixel value
        % of 1 corresponds to the foreground and the value of 0 corresponds
        % to the background. 
        
        %MinimumBackgroundRatio is a hyperparameter which needs to
        %carefully set after tuning.
        
        obj.detector = vision.ForegroundDetector('NumGaussians', 15, ...
            'NumTrainingFrames', 40, 'MinimumBackgroundRatio', 0.1, 'InitialVariance',0.05 );
        
         %MinimumBlobArea and  MaximumBlobArea are hyperparameters which need to
        %carefully set after tuning.
        
        obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
            'AreaOutputPort', true, 'CentroidOutputPort', true, ...
            'MinimumBlobArea', min_cellarea, 'MaximumBlobArea', max_cellarea, 'MajorAxisLengthOutputPort', true, ...
            'MinorAxisLengthOutputPort', true, ...
            'OrientationOutputPort', true,  'EccentricityOutputPort', true,'Connectivity',8);
    end

%% Initialize Tracks
  
    function tracks = initializeTracks()
        % create an empty array of tracks
        tracks = struct(...
            'id', {}, ...
            'bbox', {}, ...
            'kalmanFilter', {}, ...
            'age', {}, ...
            'area',{},...
            'majoraxis', 0, ...
            'minoraxis',0, ...
            'orientation',0.0, ...
            'eccentricity',0.0, ...
            'totalVisibleCount', {}, ...
            'centroid', 0.0, ...
            'consecutiveInvisibleCount', {});
    end

%% Read a Video Frame
% Read the next video frame from the video file.
    function frame = readFrame()
        frame = obj.reader.step();
        
    end

%% Detect Objects

    function [areas,centroids, bboxes, mask, majoraxis, minoraxis, orientation,eccentricity] = detectObjects(frame,frame_num)
        
        % Detect foreground.
        mask = obj.detector.step(frame);
        
        % Apply morphological operations to remove noise and fill in holes.
        mask = imopen(mask, strel('rectangle', [3,3]));
        mask = imclose(mask, strel('rectangle', [15 15])); 
        mask = imfill(mask, 'holes');
 
        % Perform blob analysis to find connected components.
        [areas, centroids, bboxes, majoraxis, minoraxis, orientation,eccentricity] = obj.blobAnalyser.step(mask);
        
    end

%% Predict New Locations of Existing Tracks
% Use the Kalman filter to predict the centroid of each track in the
% current frame, and update its bounding box accordingly.

    function predictNewLocationsOfTracks()
        for i = 1:length(tracks)
            bbox = tracks(i).bbox;
            
            % Predict the current location of the track.
            predictedCentroid = predict(tracks(i).kalmanFilter);
            
            % Shift the bounding box so that its center is at 
            % the predicted location.
            predictedCentroid = int32(predictedCentroid) - bbox(3:4) / 2;
            tracks(i).bbox = [predictedCentroid, bbox(3:4)];
        end
    end

%% Assign Detections to Tracks

    function [assignments, unassignedTracks, unassignedDetections] = ...
            detectionToTrackAssignment()
        
        nTracks = length(tracks);
        nDetections = size(centroids, 1);
        
        % Compute the cost of assigning each detection to each track.
        cost = zeros(nTracks, nDetections);
        for i = 1:nTracks
            cost(i, :) = distance(tracks(i).kalmanFilter, centroids);
        end
        
        % Solve the assignment problem.
        costOfNonAssignment = cost_nonassignment;
        [assignments, unassignedTracks, unassignedDetections] = ...
            assignDetectionsToTracks(cost, costOfNonAssignment);
    end

%% Update Assigned Tracks

    function updateAssignedTracks()
        numAssignedTracks = size(assignments, 1);
        for i = 1:numAssignedTracks
            trackIdx = assignments(i, 1);
            detectionIdx = assignments(i, 2);
            centroid = centroids(detectionIdx, :);
            bbox = bboxes(detectionIdx, :);
            area = areas(detectionIdx);
            major = majoraxis(detectionIdx);
            minor = minoraxis(detectionIdx);
            orient = orientation(detectionIdx);
            ecccent = eccentricity(detectionIdx);
            
            
            % Correct the estimate of the object's location
            % using the new detection.
            correct(tracks(trackIdx).kalmanFilter, centroid);
            
            % Replace predicted bounding box with detected
            % bounding box.
            tracks(trackIdx).bbox = bbox;
            
            % Update track's age.
            tracks(trackIdx).age = tracks(trackIdx).age + 1;
            
             % Update track's area.
            tracks(trackIdx).area = area;
            
              % Update track's majoraxis.
            tracks(trackIdx).majoraxis = major;
            
            % Update track's minoraxis.
            tracks(trackIdx).minoraxis = minor;
            
            % Update track's orientation.
            tracks(trackIdx).orientation = orient;
            
             % Update track's eccentricity.
            tracks(trackIdx).eccentricity = ecccent;
                       
             % Update track's centroid.
            tracks(trackIdx).centroid = centroid;
            
            % Update visibility.
            tracks(trackIdx).totalVisibleCount = ...
                tracks(trackIdx).totalVisibleCount + 1;
            tracks(trackIdx).consecutiveInvisibleCount = 0;
        end
    end

%% Update Unassigned Tracks
% Mark each unassigned track as invisible, and increase its age by 1.

    function updateUnassignedTracks()
        for i = 1:length(unassignedTracks)
            ind = unassignedTracks(i);
            tracks(ind).age = tracks(ind).age + 1;
            tracks(ind).consecutiveInvisibleCount = ...
                tracks(ind).consecutiveInvisibleCount + 1;
        end
    end

%% Delete Lost Tracks

    function deleteLostTracks()
        if isempty(tracks)
            return;
        end
        
        invisibleForTooLong = invisibilityduration;
        ageThreshold = 4;
        
        ages = [tracks(:).age];
        totalVisibleCounts = [tracks(:).totalVisibleCount];
        visibility = totalVisibleCounts ./ ages;
           
        lostInds = (ages < ageThreshold & visibility < 0.05) | ...
            [tracks(:).consecutiveInvisibleCount] >= invisibleForTooLong;
        
        % Delete lost tracks.
        tracks = tracks(~lostInds);
    end

%% Create New Tracks

    function createNewTracks()
        centroids = centroids(unassignedDetections, :);
        bboxes = bboxes(unassignedDetections, :);
        
        for i = 1:size(centroids, 1)
            
            centroid = centroids(i,:);
            bbox = bboxes(i, :);
            
            % Create a Kalman filter object.
            kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
                centroid, [20,50 ], [10, 25], 10);
            
            
            % Create a new track.
            newTrack = struct(...
                'id', nextId, ...
                'bbox', bbox, ...
                'centroid', 0.0, ...
                'kalmanFilter', kalmanFilter, ...
                'age', 1, ...
                'area', 0, ...
                'majoraxis', 0, ...
                'minoraxis',0, ...
                'orientation',0.0, ...
                'eccentricity',0.0, ...
                'totalVisibleCount', 1, ...
                'consecutiveInvisibleCount', 0);
            
            % Add it to the array of tracks.
            tracks(end + 1) = newTrack;
            
            % Increment the next id.
            nextId = nextId + 1;
        end
    end

%% Display Tracking Results

    function displayTrackingResults()
        % Convert the frame and the mask to uint8 RGB.
        frame = im2uint8(frame);
        oldmask=mask;
        mask = uint8(repmat(mask, [1, 1, 3])) .* 255;
        
        minVisibleCount = 2;
        
    
        if ~isempty(tracks)
              
           reliableTrackInds = ...
                [tracks(:).totalVisibleCount] > minVisibleCount;
            reliableTracks = tracks(reliableTrackInds);
            
            % Display the objects. If an object has not been detected
            % in this frame, display its predicted bounding box.
            if ~isempty(reliableTracks)
                % Get bounding boxes.
                bboxes = cat(1, reliableTracks.bbox);
                
                % Get ids.
                ids = int32([reliableTracks(:).id]);
                       
                % Get areas
                areas_ids = int32([reliableTracks(:).area]);
                orient_val = [reliableTracks(:).orientation];
               
                majoraxis_val = [reliableTracks(:).majoraxis];
                minoraxis_val = [reliableTracks(:).minoraxis];
                eccentricity_val = [reliableTracks(:).eccentricity];
                  
                  
                centroid_val = [reliableTracks(:).centroid];
                  
                
         
         j=size(ids)  ; 
         
        for i = 1:1:j(2)
          
           
           newpos(ids(i),1)=centroid_val(1,2*i-1);
           newpos(ids(i),2)=centroid_val(1,2*i); 
          

        end
            

   for i =1:1:j(2)
    if ~isempty(oldpos(i,:))
        
%Check if the centroid has not changed

  if oldpos(i,:)==newpos(i,:) 
     
       stationary_frame(i)=stationary_frame(i)+1;
     
  end
        %If the cell has remained stationary for 'num_stationaryframes' frames due to DEP ,then
        %the count is incremented
        if stationary_frame(i) == num_stationaryframes
            resultarray(idx)=i;
            idx=idx+1;
        end
        
   end
   end
    
  %New position is equated to the old position for the next iteration
      oldpos(i,:) = newpos(i,:);
      
 
             
            %Displays the Cell ID label along with the bounding box.
            
                labels = strcat('ID:',cellstr(int2str(ids')));
                
                %Displays Area as a label if the user has set Area_label=1
                %in line 98
                    
                if Area_label==1
                   labels = strcat(labels , 'Area:',cellstr(int2str(areas_ids')));
                end
                
                
               %Displays Eccentricity as a label if the user has set Eccentricity_label=1
                %in line 99
                
                
                if Eccentricity_label==1
                   labels = strcat(labels ,  'Ecc:',cellstr(string(eccentricity_val')));
                end
                
                
               %Displays Orientation as a label if the user has set Orientation_label=1
                %in line 99
                
                
               if Orientation_label==1
                   orient_val=orient_val*180/3.1416;
                   labels = strcat(labels ,  'Orr:',cellstr(string(orient_val')));
                end
                
                
             
                % Draw the objects on the frame.
                frame = insertObjectAnnotation(frame, 'rectangle', ...
                    bboxes, labels, 'Color','cyan');
                
                % Draw the objects on the mask.
                mask = insertObjectAnnotation(mask, 'rectangle', ...
                    bboxes, labels);
                
        
            end
        end
   

       writeVideo(v,frame);
    end

end
