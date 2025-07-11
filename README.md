# Beads and giant unilamellar vesicles (GUVs)

This repository contains two ImageJ macros used for the quantification of intensity of fluorescent beads and GUVs.



## Content
- code/beads_macro.ijm : ImageJ macro
- data/beads_demo.tif : demo dataset
- code/GUV_macro.ijm : ImageJ macro
- data/GUV_demo.czi : demo dataset

## Requirements
- Fiji available from https://imagej.net/software/fiji/, tested on
    - version 1.54p
- Microsoft Excel

## Installation
Download and extract the zip file with the code and demo images.


## Intensity quantification of beads
This macro measure the fluorescence intensity of the beads surface in 2D for each channel and the diameter of the beads. 

###  Dataset
The data are multi-channel, single plane images. An example dataset is in `data/beads_demo.czi`.

### Usage
- Open the original files in Fiji
- Select all beads to analyse: draw circular ROIs around the beads in the mCherry channel and press 't' to save each ROI in the ROI Manager
- Open the macro and press "Run"
- Adjust the width of the area to measure. The width is measured in pixels, extending towards the centre of the circular ROI. 
- Results will show intensity in each channel
- Copy the intensity values for the mCherry and AF488 channels into Excel
- Measure 10 empty areas with no beads using the same procedure
- Average the readings from 10 empty areas and subtract from the intensities of the beads. This will correct for background intensity.
- Divide the AF488 channel intensity by the mCherry channel intensity. This should normalise the effect of unequal loading of the protein on the beads. 


## Intensity quantification of GUVs

The signal is segmented using a difference of Gaussian in both channels, an OR operation provides a unique mask from the two channels. The ROI from the user is utilized to solve the tracking problem and identify each GUV over time. Intensities over time are then measured for each channel and saved in the result table.
 
### Dataset
The data are single-channel, multi plane images. An example dataset is in `data/GUV_demo.tif`.
 
Data are 2D image sequences with two channels: a lissamine-rhodamine channel for visualising and tracking the GUVs, and an AF647 channel for tracking the p40-phox domain labelled with AlexaFluor647. The p40-phox domain binds PI3P produced by VPS34 and reports the production of PI3P over time.

The spherical GUVs appear as bright rings in the images and their motion is very limited.

An example dataset is in `data/GUV_demo.tif`.

### Usage
- Open the original GUV assay files with Fiji using Bio-format plugin and select open as hyperstack leaving everything else unchecked.
- Select several ROIs (draw a circle around a GUV membrane in the lissamine-rhodamine channel and press 't' to add it to ROI Manager)
- Launch the macro (Run in the editor)
- Adjust the sensitivity as needed.
- Run the macro
- The results table shows intensities for each channel over time
- Copy the results table into Excel
- Replace all '-1' values with nothing. '-1' means that the macro lost track of the GUV and did not measure an intensity value.
- Select an empty area in the micrograph (without GUVs present), measure the Z-stack in the AF647 channel (Image > Stacks > plot Z-axis profile > list) and copy into Excel. Repeat for four other empty areas. Average the empty area readings. 
- Subtract the empty area values from the measured intensities of the AF647 channel.
- Plot the background-corrected AF647 channel intensity values over time to get a reaction progress curve.
 

## Contributions
Imaging: Lauren McGinney, Yohei Ohashi and Saulė Špokaitė  
Code: Jerome Boulanger