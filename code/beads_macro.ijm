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
 */

macro "GUV Intensity vs Area" {
	// Ask parameters
	Dialog.create("Parameters");
	Dialog.addSlider("Width [px]",0.0,10.0,5.0);	
	Dialog.show();
 	bandwidth = Dialog.getNumber(); 	
    // Clean up initialization
	run("Set Measurements...", "None redirect=None decimal=3");		
	run("Select None");
	run("Clear Results"); 
	Overlay.remove();
	if (getTitle=="Intensity vs Diameter") {
		close();
	}
	// process 
	setBatchMode(true);
	createRingROI(bandwidth);	
	
	measureAreaVsIntensity(); 	
	setBatchMode(false);
}

macro "GUV Intensity vs Time" {	
	Dialog.create("Parameters");
	Dialog.addSlider("Smoothing [%]",0.0,100.0,50.0);
	Dialog.addSlider("Sensitivity [%]",0.0,100.0,50.0);	
	Dialog.addSlider("Width [px]",0.0,20.0,10.0);
	Dialog.addChoice("Measure", newArray("Mean","RawIntDen","Median","IntDen"));
	Dialog.show();
	smoothing = Dialog.getNumber();
	sensitivity = Dialog.getNumber();	
 	bandwidth = Dialog.getNumber();
 	measure = Dialog.getChoice();
 	print("GUV intensity ["+smoothing+","+sensitivity+","+bandwidth+","+measure+"]");
	guvIntensity(smoothing, sensitivity, bandwidth, measure);
	//segmentAllGUVs(smoothing/100*3, 4*(100-sensitivity)/100, bandwidth);
}


// measure AreaVsIntensity
function measureAreaVsIntensity() {	
	Stack.getDimensions(width, height, channels, slices, frames);
	// select the channel (hyperstack)
	//	Stack.setChannel(channel);
		
	
	// number of ROI with out the last one (rings)
	nroi = roiManager("count") - 1;	
	a = newArray(nroi);
	d = newArray(nroi);
	m = newArray(channels * nroi);	
	for (i = 0; i < nroi; i++) {				
		roiManager("select",i);
		List.setMeasurements;		
		d[i] =  0.5*List.getValue("Major")+0.5*List.getValue("Minor");
		// compute the intersection of the roi with the ring mask (last roi)
		roiManager("select", newArray(i, nroi));
		roiManager("AND");		
		run("Measure");
		// measure intensity and area
		List.setMeasurements;
		a[i] = List.getValue("Area");		
		m[i] = List.getValue("Mean");
		setResult("Area of the ring", i, d2s(a[i],2));
		setResult("Diameter of the ROI", i, d2s(d[i],2));
		for (c = 1; c <= channels; c++) {			
			Stack.setChannel(c);
			m[i+(c-1)*nroi] = getValue("Mean");			
			setResult("Mean Intenisty in the ring for channel " + c, i, m[i+(c-1)*nroi]);
		}
		
		// add an overlay
		run("Add Selection...", "stroke=#FF55FF width=1");
		Overlay.show();
		roiManager("Deselect");
	}
	updateResults();		
		
	// remove the ring mask
	roiManager("Select", nroi);
	roiManager("Delete");
	
	Plot.create("Intensity vs Diameter", "Diameter", "Intensity");	
	legend="";
	for (c = 1; c <= channels; c++) {		
		mc = Array.slice(m,(c-1)*nroi,c*nroi);
		Array.print(mc);
		Plot.setLineWidth(5);
		Plot.setColor("#"+round(9*random)+""+round(9*random)+""+round(9*random)+""+round(9*random)+""+round(9*random)+""+round(9*random));
		Plot.add("circles", d, mc);	
		legend=legend+"channel "+c+"\n";
	}
	Plot.setLegend(legend, "");
	Plot.setLimitsToFit();
	Plot.update();
}

Array.print(Array.slice(newArray(1,2,3,4,5,6,7,8),1,3))

function createRingROI(ring_width) {
	getDimensions(width, height, channels, slices, frames);
	newImage("Untitled", "8-bit black", width, height, 1);	
	id=getImageID;
	setForegroundColor(255,255,255);
	run("Line Width...", "line="+2*ring_width);
	roiManager("Show All");
	run("Create Selection");
	run("Enlarge...", "enlarge="+ring_width);
	roiManager("Draw");	
	setThreshold(128,255);
	run("Create Selection");
	roiManager("Add");
	closeImage(id);	
}
 
function guvIntensity(smoothing, sensitivity, bandwidth, measure)  {
 	
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
	setBatchMode(true);
	
	segmentAllGUVs(smoothing/100.0*3.0, 4.0*(100-sensitivity)/100.0, bandwidth);

	measureIntensities(bandwidth, measure);
	
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
	setBatchMode(false);
	print("Done");
}

// Segmentation of all images
function segmentAllGUVs(smoothing, threshold, bandwidth) {	
	setBatchMode(true);
	id = getImageID;	
	run("Duplicate...", "duplicate channels=1");
	id1 = getImageID;
	segment(smoothing, threshold);
	selectImage(id);
	run("Duplicate...", "duplicate channels=2");
	id2 = getImageID;
	segment(smoothing, threshold);
	imageCalculator("OR stack", id1, id2);	
	getOutlines(bandwidth);	
	setThreshold(128,255);	
	getDimensions(width, height, channels, slices, frames);
	for (t = 1; t <= frames; t++) {
		if (frames > 1) {
			Stack.setFrame(t);
		}
		run("Create Selection");
		roiManager("Add");		
	}
	selectImage(id1);close();
	//selectWindow("ROI Manager");
	setBatchMode(false);
	}
}

function segment(scale, lambda) {	
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
	if (nSlices > 1) {
		Stack.getStatistics(voxelCount, mean, min, max, std);
	} else {
		getStatistics(area, mean, min, max, std);
	}
	threshold = mean + lambda * std;
	setThreshold(threshold, max);	
	run("Convert to Mask", "method=Default background=Default");			
	smoothContour(20,5,3);	
	}
}

// Get the outline of a mask
function getOutlines(size) {
	id = getImageID;
	run("Duplicate...", "duplicate ");
	id1 = getImageID;	
	run("Fill Holes", "stack");	
	smoothContour(20,5,3);	
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
function measureIntensities(bandsize, measure)  {
	has_empty_rois = false;
	getDimensions(width, height, channels, slices, frames);
	for (i = 0; i < nroi; i++) {
		roiManager("select", i);
		name = Roi.getName();	
		for (t = 1; t <= frames; t++) {
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
				}
				// add an overlay
				run("Add Selection...", "stroke=##9999ff width=1");
				Overlay.setPosition(t);
				Overlay.show();
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

function closeImage(id) {
		selectImage(id); 
		close();
}
