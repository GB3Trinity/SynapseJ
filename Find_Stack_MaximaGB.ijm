// Find Stack Maxima
//
// This macro runs the Process>Binary>Find Maxima
// command on all the images in a stack.

  Dialog.create("Find Maxima");
  Dialog.addNumber("Threshold:", 200);
  Dialog.addNumber("Noise Tolerance:", 5);
  Dialog.addChoice("Output Type:", newArray("Single Points", "Maxima (Exact)", "Maxima Within Tolerance", "Segmented Particles", "Count"));
  Dialog.addCheckbox("Exclude Edge Maxima", false);
  Dialog.addCheckbox("Light Background", false);
  Dialog.addCheckbox("Above Lower Threshold", false);
  Dialog.show();
  threshold = Dialog.getNumber();
  tolerance = Dialog.getNumber();
  type = Dialog.getChoice();
  exclude = Dialog.getCheckbox();
  light = Dialog.getCheckbox();
  above = Dialog.getCheckbox ();
  options = "";
  if (exclude) options = options + " exclude";
  if (light) {
	options = options + " light";
	if (above) print("Can't find minima on a thresholded image. Ignoring threshold request.");
  } else if (above) options = options + " above";
  setBatchMode(true);
  input = getImageID();
  n = nSlices();
  for (i=1; i<=n; i++) {
     selectImage(input);
     setSlice(i);
     if (above) setThreshold(threshold, 4095);
     run("Find Maxima...", "noise="+ tolerance +" output=["+type+"]"+options);
     if (i==1)
        output = getImageID();
    else if (type!="Count") {
       run("Select All");
       run("Copy");
       close();
       selectImage(output);
       run("Add Slice");
       run("Paste");
    }
  }
  run("Select None");
  setBatchMode(false);
