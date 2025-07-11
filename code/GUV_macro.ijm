/*
 * Analyse the intensity of GUV over time
 * 
 * Data are 2D image sequence with two channels.
 * The spherical GUVs apprear as bright rings in the images and 
 * their motion is very limited.
 * 
 * The signal is segmented using a difference of Gaussian in both channels
 * an OR operation provide a unique mask from the two channels.
 * 
 * The ROI from the user is then utilized to solve the tracking problem 
 * and identify each GUV for each other over time
 * 
 * Intensities overtime is then measured for each channel and object and 
 *  save in the result table.
 * 
 * Usage:
 * - Open the original files using Bioformat and select open as hyperstack levaving evering thing else unchecked.
 * - Select several ROI (draw region and press t)
 * - Launch the macro (Run in the editor)
 * 
 * Jerome Boulanger 2016 for Lauren McGinney and Yohei Ohashi
 * Modified in mar 2018 for error of image focus + outlines
 */
 
macro "GUV Intensity" {	
	Stack.getDimensions(width, height, channels, slices, frames);
	Dialog.create("Parameters");
	Dialog.addSlider("Smoothing [%]",0.0,100.0,50.0);
	Dialog.addSlider("Sensitivity [%]",0.0,100.0,50.0);	
	Dialog.addSlider("Width [px]",0.0,20.0,10.0);
	Dialog.addChoice("Measure", newArray("Mean","RawIntDen","Median","IntDen"));
	Dialog.addSlider("First frame",1,frames,1);
	Dialog.addSlider("Last frame",1,frames,frames);	
	Dialog.show();
	smoothing = Dialog.getNumber();
	sensitivity = Dialog.getNumber();	
 	bandwidth = Dialog.getNumber();
 	measure = Dialog.getChoice();
 	first_frame = Dialog.getNumber();
 	last_frame = Dialog.getNumber();	
 	print("GUV intensity ["+smoothing+","+sensitivity+","+bandwidth+","+measure+"]"); 	
	guvIntensity(smoothing, sensitivity, bandwidth, measure, first_frame, last_frame);
	//segmentAllGUVs(smoothing/100*3, 4*(100-sensitivity)/100, bandwidth);
}

function guvIntensity(smoothing, sensitivity, bandwidth, measure, first_frame, last_frame) {
 	
	// Check the number of ROI in the ROI manager
	nroi = roiManager("count");
	while (nroi == 0) {
		waitForUser("Please select ROI and add them to the ROI manager");
		nroi = roiManager("count");
	}
	print("Analysis of " + nroi + " regions.");
			
	// Clean up initialization
	run("Set Measurements...", "None redirect=None decimal=3");	
	run("Select None");
	run("Clear Results"); 
	Overlay.remove();
	//setBatchMode(true);
	id = getImageID;
	print("Segment all GUV");
	segmentAllGUVs(smoothing/100.0*3.0, 4.0*(100-sensitivity)/100.0, bandwidth, first_frame, last_frame);
	selectImage(id);
	print("Measure intensity");
	measureIntensities(bandwidth, measure, first_frame, last_frame);
	
	// Clean up created ROIs	
	sel = newArray(roiManager("count") - nroi);	
	for (i = 0; i< sel.length; i++) {
		sel[i] = nroi + i;
	}
	roiManager("Select", sel);
	roiManager("Delete");
	run("Select None");
	
	Stack.setFrame(1);
	Stack.setChannel(1);
	//setBatchMode(false);
	print("Done");
}

function segmentAllGUVs(smoothing, threshold, bandwidth, first_frame, last_frame) {	
	/* Segmentation of all images of the sequence */
	
	id = getImageID;	
	print("Segment channel 1");
	run("Duplicate...", "title=ch1 duplicate channels=1");
	id1 = getImageID;
	segment(smoothing, threshold);
	
	selectImage(id);
	print("Segment channel 2");
	run("Duplicate...", "title=ch2 duplicate channels=2");
	id2 = getImageID;	
	segment(smoothing, threshold);
	
	imageCalculator("OR stack", id1, id2);	
	
	getOutlines(bandwidth);	
	
	setThreshold(128,255);

	print("Create selection at each frame");
	for (t = first_frame; t <= last_frame; t++) {
		Stack.setFrame(t);
		print(t, getValue("Max"));
		run("Create Selection");
		roiManager("Add");		
	}
	selectImage(id1);close();
	selectImage(id2);close();
	selectImage(id);
	//selectWindow("ROI Manager");	
}


function segment(scale, lambda) {
	print("segment with scale:"+scale+"px and threshold:"+lambda);
	id1 = getImageID;
	run("32-bit");
	run("Square Root", "stack");
	run("Gaussian Blur...", "sigma="+scale+" stack");
	run("Duplicate...", "duplicate ");
	id2 = getImageID;
	run("Gaussian Blur...", "sigma="+3*scale+" stack");	
	imageCalculator("Subtract stack 32-bit", id1, id2);
	selectImage(id2); close();
	selectImage(id1);	
	Stack.getStatistics(voxelCount, mean, min, max, std)
	threshold = mean + lambda * std;
	setThreshold(threshold, max);	
	run("Convert to Mask", "method=Default background=Default");			
	//smoothContour(20,5,3);	
}

function getOutlines(size) {
	/*
	 * Get the outline of the GUV
	 */
	id = getImageID;
	run("Duplicate...", "duplicate ");
	id1 = getImageID;	
	run("Fill Holes", "stack");	
	//smoothContour(20,5,3);	
	run("Duplicate...", "duplicate ");
	id2 = getImageID;
	run("Minimum...", "radius="+size+" stack");	
	imageCalculator("XOR stack", id1, id2);	
	selectImage(id2); close();
	imageCalculator("AND stack", id, id1);	
	selectImage(id1); close();
	selectImage(id);	
}

function smoothContour(iter, r1, r2) {
	for (i = 0; i < iter; i++) {
		run("Maximum...", "radius="+r1+" stack");
		run("Minimum...", "radius="+r1+" stack");
		run("Median...", "radius="+r2+" stack");
	}
}

// Measure intensities for each ROI and frame
function measureIntensities(bandsize, measure, first_frame, last_frame)  {
	has_empty_rois = false;
	getDimensions(width, height, channels, slices, frames);
	for (i = 0; i < nroi; i++) {
		roiManager("select", i);
		name = Roi.getName();	
		for (t = first_frame; t <= last_frame; t++) {
			Stack.setFrame(t);
			// create a region in the ROI from the mask			
			roiManager("select", newArray(i, nroi + t - 1));
			roiManager("AND");		
			getSelectionBounds(x, y, w, h);
			if ((w != width) || (h != height)) {
				// measure intensities
				for (c = 1; c <= channels; c++) {
					Stack.setChannel(c);
					Stack.setFrame(t);					
					List.setMeasurements;
					setResult(name + "-ch"+c, t-1, d2s(List.getValue(measure),2));		
					sn = getSliceNumber();
					// add an overlay					
					run("Add Selection...", "stroke=#9999ff width=1");
					Overlay.setPosition(c, 1, t);
					Overlay.add;		
				}
			} else {	
				has_empty_rois = true;
				// Error: the Roi is empty, we just put -1 in the table
				for (c = 1; c <= channels; c++) {
					setResult(name + "-ch"+c, t-1, -1);
				}
			}
		}
	}
	updateResults();
	if (has_empty_rois)  {
		print("*** Warning ***\nUnable to segment all objects.\nSetting values to -1 in the result table.\nPlease try to modify the sensitivity\n***********\n");
	}
}
