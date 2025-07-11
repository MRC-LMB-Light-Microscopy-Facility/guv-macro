Analyse the fluorecence intensity on GUVs over time
 
Data are 2D image sequences with two channels: a lissamine-rhodamine channel for visualising and tracking the GUVs, and an AF647 channel for tracking the p40-phox domain labelled with AlexaFluor647. The p40-phox domain binds PI3P produced by VPS34 and reports the production of PI3P over time.

The spherical GUVs appear as bright rings in the images and their motion is very limited.

The signal is segmented using a difference of Gaussian in both channels.
an OR operation provides a unique mask from the two channels.

The ROI from the user is utilized to solve the tracking problem and identify each GUV over time.

Intensities over time are then measured for each channel and saved in the result table.
 
Usage:
- Open the original GUV assay files with FIJI using Bio-format plugin and select open as hyperstack leaving everything else unchecked.
- Select several ROIs (draw a circle around a GUV membrane in the lissamine-rhodamine channel and press 't' to add it to ROI Manager)
- Launch the macro (Run in the editor)
- Adjust the sensitivity as needed.
- Run the macro
- The results table shows intensities for each channel over time
- Copy the results table into Excel
- replace all '-1' values with nothing. '-1' means that the macro lost track of the GUV and did not measure an intensity value.
- Select an empty area in the micrograph (without GUVs present), measure the Z-stack in the AF647 channel (Image > Stacks > plot Z-axis profile > list) and copy into excel. Repeat for four other empty areas. Average the empty area readings. 
- Subtract the empty area values from the measured intensities of the AF647 channel.
- Plot the background-corrected AF647 channel intensity values over time to get a reaction progress curve.
 
 Jerome Boulanger 2016 for Lauren McGinney and Yohei Ohashi
 Modified in mar 2018 for error of image focus + outlines
