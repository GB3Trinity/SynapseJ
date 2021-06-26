////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// The macro will take user input to identify and measure puncta and determine those that are synaptic.
// There is a PDF document distributed with this that explains the parameters.This software is subject to GPL v.3
// Please cite all usage and derivatives by citing the paper from BioRxIV at: 
// SynapseJ: an automated, synapse identification macro for ImageJ
// Juan Felipe Moreno Manrique, Parker R. Voit, Kathryn E. Windsor, Aamuktha R. Karla, Sierra R. Rodriguez, and 
// Gerard M Beaudoin III. bioRxiv 2021.06.24.449851; doi: https://doi.org/10.1101/2021.06.24.449851
// https://biorxiv.org/cgi/content/short/2021.06.24.449851v1
//
// Please cite this work when using this data or analysis. For example:
// Moreno Manrique, J.F., Voit, P.R., Windsor, K.E., Karla, A.R., Rodriguez, S.R., and Beaudoin, G.M. (2021). 
// SynapseJ: an automated, synapse identification macro for // ImageJ. bioRxiv, 2021.2006.2024.449851.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
var scale,unit;
var cellseparator = "\t";


macro "SynapseJ v.1" {
	run("ROI Manager...");
	print("\\Clear");
	type="Tiff";
	Channels = newArray("C1","C2","C3","C4","N/A");
//	Colors = newArray("c1=[", "c2=[", "c3=[", "c4=[");
	Colors = newArray("c1=", "c2=", "c3=", "c4=");
	ImTypes = newArray(".tif");
	resultLabel = newArray("Label","Area","Mean","Min","Max","X","Y","XM","YM","Perim.","Feret","IntDen","RawIntDen","FeretX","FeretY","FeretAngle","MinFeret");

	print("Select source directory with image files");
	sourcedir=getDirectory("select source directory with image files");
	print("Select or create destination directory");
	destdir=getDirectory("select or create destination directory");

	Dialog.create("Settings");
	Dialog.addChoice("Presynaptic Channel ",Channels,Channels[3]);
	Dialog.addChoice("Postsynaptic Channel ",Channels,Channels[2]);
	Dialog.addChoice("Presynaptic Marker Channel ",Channels,Channels[1]);
        Dialog.addChoice("Postsynaptic Marker Channel ",Channels,Channels[0]);
//	Dialog.addChoice("Image Type ",ImTypes,ImTypes[1]);
	Dialog.addNumber("Pre Min: ", 658);
	Dialog.addNumber("Pre Noise: ",350);
	Dialog.addNumber("Pre Low Size: ", 0.08);	
	Dialog.addNumber("Pre High Size: ", 2.5);
	Dialog.addCheckbox("Pre Median Blur? ", true);
	Dialog.addNumber("Pre Blur pixel radius: ", 2);
	Dialog.addNumber("Pre BKD: ", 0);
	Dialog.addCheckbox("Use Find Maxima for Pre? ", true);
	Dialog.addCheckbox("Fading Correction? ", false);
	Dialog.addNumber("Post Min: ", 578);
	Dialog.addNumber("Post Noise: ",350);
	Dialog.addNumber("Post Low Size: ", 0.08);	
	Dialog.addNumber("Post High Size: ", 2.5);
	Dialog.addCheckbox("Post Median Blur? ", true);
	Dialog.addNumber("Post Blur pixel radius: ", 2);
	Dialog.addNumber("Post BKD: ", 0);
	Dialog.addCheckbox("Use Find Maxima for Post? ", true);
	Dialog.addCheckbox("Fading Correction? ", false);
	Dialog.addNumber("No. of Pixel Overlap: ", 1);
	Dialog.addCheckbox("Dilate for Colocalization? ", false);
	Dialog.addNumber("Dilate No. of pixels: ", 1);
	Dialog.addNumber("Slice Number: ", 2);
	

	Dialog.show();
	PreCol = Dialog.getChoice();
	PostCol = Dialog.getChoice();
	ThrCol = Dialog.getChoice();
        PstR = Dialog.getChoice();
//	SetType = Dialog.getChoice();
	PreMin = Dialog.getNumber();
	PreNoiseL = Dialog.getNumber();
	PreSzLo = Dialog.getNumber();
	PreSzHi = Dialog.getNumber();
	PreBlurQ = Dialog.getCheckbox();
	PreBlurPx = Dialog.getNumber();
	BkdPre = Dialog.getNumber()
	PreMax = Dialog.getCheckbox();
	fadedPre = Dialog.getCheckbox();
	PostMin = Dialog.getNumber();
	PostNoiseL = Dialog.getNumber();
	PostSzLo = Dialog.getNumber();
	PostSzHi = Dialog.getNumber();
	PostBlurQ = Dialog.getCheckbox();
	PostBlurPx = Dialog.getNumber();
	BkdPost = Dialog.getNumber();
	PostMax = Dialog.getCheckbox();
	fadedPost = Dialog.getCheckbox();
	OverNo = Dialog.getNumber();
	dilateQ = Dialog.getCheckbox();
	dilatePx = Dialog.getNumber();
	SliceNo = Dialog.getNumber();


	SliceIntPre = newArray(SliceNo);	
	SliceIntPost = newArray(SliceNo);
	SliceInt3 = newArray(SliceNo);
	SliceInt4 = newArray(SliceNo);
	for (s = 0; s<SliceNo; s++) {
		SliceIntPre[s] = 1;
		SliceIntPost[s] = 1;
		SliceInt3[s] = 1;
		SliceInt4[s] = 1;
	}

	if (fadedPre) {
		SliceIntPre = fadingCorr(SliceIntPre, "Pre ");
	}
	if (fadedPost) {
		SliceIntPost = fadingCorr(SliceIntPost, "Post ");
	}
	if (ThrCol == Channels[4]) {
		ThrQ = false;
	} else ThrQ = true;
	if (ThrQ) {
        	Dialog.create("Presynaptic Marker Settings");
		Dialog.addNumber("Thr Max Int > ", 895);
		Dialog.addNumber("Thr Min Int > ", 484);
		Dialog.addNumber("Thr Sz > ", 250);
		Dialog.show();
     		ThrHi = Dialog.getNumber();
    		ThrLo = Dialog.getNumber();
 		ThrSz = Dialog.getNumber();
	}
	if (PstR == Channels[4]) {
		ForQ = false;
	} else ForQ = true;
	if (ForQ) {
		Dialog.create("Postsynaptic Marker Settings");
        	Dialog.addNumber("For Max Int > ", 692);
		Dialog.addNumber("For Min Int > ", 273);
		Dialog.addNumber("For Sz > ", 300);
		Dialog.show();
     		ForHi = Dialog.getNumber();
    		ForLo = Dialog.getNumber();
 		ForSz = Dialog.getNumber();
	}

	setBatchMode(true);

	StkQ = "";
	if (SliceNo > 1) StkQ = "stack";

	setBackgroundColor(0,0,0);
	setForegroundColor(255,255,255);
	run("Options...", "iterations=1 count=1 black edm=Overwrite");

	mergedir=destdir+"merge";
	File.makeDirectory(mergedir);
	exceldir=destdir+"excel";
	File.makeDirectory(exceldir);

	list = getFileList(sourcedir);
	row=0;
	LABEL = newArray(list.length);
  	Syn = newArray(list.length);
	SynPre = newArray(list.length); 
            ThrPre = newArray(list.length);
            ForPost = newArray(list.length);
	Pre = newArray(list.length);
	Post = newArray(list.length);

	print("Measuring Presynaptic marker "+PreCol+" channel at noise "+PreNoiseL+" above "+PreMin+" bigger than "+PreSzLo+" and smaller than "+PreSzHi);
	if (PreBlurQ) {
		print("Presynaptic puncta are median blurred "+PreBlurPx+" pixels");
	} else print("Presynaptic puncta are not blurred");
	if (BkdPre >0) {
		print("Background removed with a pixel radius of "+BkdPre);
	} else print("Background is not removed");
	if (fadedPre) {
		print("Correcting fading of presynaptic signal:");
		for (fpre = 0; fpre<SliceNo; fpre++) print(SliceIntPre[fpre]);
	} else print("Presynaptic signal is not faded");
	if (PreMax) {
		print("Using 'Find Maxima�' to find presynaptic puncta in a dense image.");
	} else print("Just using Threshold to find presynaptic puncta in a sparse image.");
	if (ThrQ) {
		print("Measuring Presynaptic marker labeled with pre-synaptic neuronal marker "+ThrCol+" channel with minimum intensity above "+ThrLo+
			",\n     maximum intensity above "+ThrHi+", and entered size was "+ThrSz);
	} else print("No third marker channel.");
	print("Measuring Postsynaptic marker "+PostCol+" channel at noise "+PostNoiseL+" above "+PostMin+" bigger than "+PostSzLo+" and smaller than "+PostSzHi);
	if (PostBlurQ) {
		print("Postsynaptic puncta are median blurred "+PostBlurPx+" pixels");
	} else print("Postsynaptic puncta are not blurred");
	if (BkdPost >0) {
		print("Background removed with a pixel radius of "+BkdPost);
	} else print("Background is not removed");
	if (fadedPost) {
		print("Correcting fading of postsynaptic signal:");
		for (fpost = 0; fpost<SliceNo; fpost++) print(SliceIntPost[fpost]);
	} else print("Postsynaptic signal is not faded");
	if (PostMax) {
		print("Using 'Find Maxima�' to find postsynaptic puncta in a dense image.");
	} else print("Just using Threshold to find postsynaptic puncta in a sparse image.");
            if (ForQ) {
		print("Measuring Postsynaptic marker labeled with post-synaptic neuronal marker "+PstR+" channel with minimum intensity above "+ForLo+
			",\n     maximum intensity above "+ForHi+", and entered size was "+ForSz);
	} else print("No fourth marker channel.");
	if (dilateQ) {
		print("Spots dilated "+dilatePx+" pixels");
	} else print("Spots are not dilated");
	if (OverNo > 1) {
		print("Restricting synaptic puncta to those that overlap by "+OverNo+" pixels in the pre- and post-synaptic channels.");
	} else print("Synaptic puncta are not restricted by the amount of overlap between the pre- and post-synaptic channels.");

	run("Set Measurements...", "area mean min centroid center perimeter feret's integrated limit display redirect=None decimal=3");
	roiManager("Associate", "true");

	titlePreW = "All Pre Results";
	titlePreV = "["+titlePreW+"]";
	titlePostW = "All Post Results";
	titlePostV = "["+titlePostW+"]";
	titlePreRW = "Syn Pre Results";
	titlePreRV = "["+titlePreRW+"]";
	titlePostRW = "Syn Post Results";
	titlePostRV = "["+titlePostRW+"]";

	PreAllNo = 0;

	titleW = "Pre to Post Correlation Window";
	titleV = "["+titleW+"]";
	if (!isOpen(titleW)) {
		run("New... ", "name="+titleV+" type=[Text File] width=100 height=500");
	} else if (isOpen(titleW)) {
		print(titleV, "\\Update:");
	}
	header = "Image Name";
	for (z = 1; z<resultLabel.length; z++) header = header+"\t"+resultLabel[z];
	headerV = header + "\t"+header+"\tNo. of Post/Pre Puncta \tPost IntDen\tPostsynaptic Puncta No.\tOverlap\tDistance\tDistance M\n";
	print(titleV, headerV);
	titleU = "Post to Pre Correlation Window";
	titleX = "["+titleU+"]";
	if (!isOpen(titleU)) {
		run("New... ", "name="+titleX+" type=[Text File] width=100 height=500");
	} else if (isOpen(titleU)) {
		print(titleX, "\\Update:");
	}
	headerX = header + "\t"+header +"\tNo. of Pre/Post Puncta \tPre IntDen\tPresynaptic Puncta No.\tOverlap\tDistance\tDistance M\n";
	print(titleX, headerX);

	for (i=0; i<list.length; i++) {
		path = sourcedir+list[i];
		if (endsWith(path, ".tif") || endsWith(path, ".nd2" )) {
	 		open(path);
			roiManager("Reset");
			while (nImages == 0) {
				wait(10);
 	    		}
			name=getTitle();
			print(name);
			LABEL[row] = name;
			if (indexOf(name, ".tif") > 0) nameSh = substring(name,0,lastIndexOf(name, ".tif"));
			if (indexOf(name, ".nd2") > 0) nameSh = substring(name,0,lastIndexOf(name, ".nd2"));
			getScaleAndUnit();
			run("Set Scale...", "distance="+scale+" known=1 pixel=1 unit="+unit+" global");
			selectWindow(name);
			rename("image");
			run("Split Channels");
			if (ThrQ) LUPThr = ThrCol+"-image";
            		if (ForQ) LUPFor = PstR+"-image";
			Pre[row] = PrepChannel(nameSh,PreCol, fadedPre, SliceIntPre, BkdPre, PreMin, PreNoiseL, PreSzLo, PreSzHi, dilateQ, dilatePx, PreBlurQ, PreBlurPx, StkQ, PreMax);
			if (PreMax) {
				LUPPre = "Mask of "+PreCol+"-image Segmented";
			} else LUPPre = "Mask of "+PreCol+"-image";
			STRPre = "Result of "+PreCol+"-image";
			if (Pre[row] != 0) {
				selectWindow("Results");
				saveAs("Text", destdir+File.separator+nameSh+"Pre.txt");
				if (isOpen(titlePreW)) {
					CollateResults(titlePreW, resultLabel);
				} else {
					selectWindow("Results");
					IJ.renameResults(titlePreW);
				}
				roiManager("Save", destdir+ File.separator +nameSh+"PreALLRoiSet.zip");
				if (ThrQ) {
					selectWindow(LUPThr);
					run("Median...", "radius="+PreBlurPx+" stack");
					CoLocROI(LUPThr, STRPre, LUPPre, ThrHi, ThrLo, ThrSz, StkQ);
					ThrPre[row] = roiManager("count");
					if (ThrPre[row] != 0) {
						roiManager("deselect");
						roiManager("Save", destdir+ File.separator +nameSh+"PreThrRoiSet.zip");
						roiManager("Measure");
						saveAs("Measurements", exceldir+ File.separator +nameSh+"PreThrResults.txt");
					}
				}
				roiManager("reset");
			}	
			Post[row] = PrepChannel(nameSh,PostCol, fadedPost, SliceIntPost, BkdPost, PostMin, PostNoiseL, PostSzLo, PostSzHi, dilateQ, dilatePx, PostBlurQ, PostBlurPx, StkQ, PostMax);
			if (PostMax) {
				LUPPost = "Mask of "+PostCol+"-image Segmented";
			} else LUPPost = "Mask of "+PostCol+"-image";
			STRPost = "Result of "+PostCol+"-image";
//print("Thar She Blows");
			if (Post[row] != 0) {
				selectWindow("Results");
				saveAs("Text", destdir+ File.separator +nameSh+"Post.txt");
				if (isOpen(titlePostW)) {
//					String.copyResults;
					CollateResults(titlePostW, resultLabel);
				} else {
					selectWindow("Results");
					IJ.renameResults(titlePostW);
				}
				run("Clear Results");
				roiManager("Save", destdir+ File.separator +nameSh+"PostALLRoiSet.zip");	
				if (ForQ) {
					selectWindow(LUPFor);
					run("Median...", "radius="+PostBlurPx+" stack");
					CoLocROI(LUPFor, STRPost, LUPPost, ForHi, ForLo, ForSz, StkQ);
					ForPost[row] = roiManager("count");
					if ( ForPost[row] != 0) {
						roiManager("deselect");
						roiManager("Save", destdir+ File.separator +nameSh+"PstRRoiSet.zip");
						roiManager("Measure");
						saveAs("Measurements", exceldir+ File.separator +nameSh+"PstRResults.txt");
					}
				}
			}

			if (Post[row] != 0 &&  Pre[row] != 0 ) {
				AssocROI(STRPre, STRPost, LUPPost, 0, StkQ, OverNo, PreMin);  //Store Pre hasnt been cleaned for the third channel
				if (roiManager("count") > 0) {
					roiManager("Deselect");
					roiManager("Save", destdir+ File.separator +nameSh+"PostSYNRoiSet.zip");
					selectWindow(STRPost);
					saveAs("tiff", destdir + File.separator +nameSh+"PostF.tif");
					rename(nameSh+"PostF.tif");
					STRPost = nameSh+"PostF.tif";
					PostC = roiManager("count");
					ValuesPost = newArray(PostC);
					for (v = 0; v<PostC; v++) ValuesPost[v]=v+1;
					roiManager("Measure");
					Syn[row] = nResults;
//					if (isOpen(titlePostRW)) {
//						String.copyResults;
//						CollateResults(titlePostRW, resultLabel);
//					}
					saveAs("Measurements", exceldir+ File.separator +nameSh+"PostResults.txt");
					roiManager("Deselect");
					PostX = FillArray("X",PostC);
					PostY = FillArray("Y",PostC);
					PostXM = FillArray("XM",PostC);
					PostYM = FillArray("YM",PostC);
					PostID = FillArray("IntDen",PostC);
					PostResult = CopyResultsTableArr(resultLabel);
					ColorROI(PostC, dilateQ, dilatePx, LUPPost);
					if (!isOpen(titlePostRW)) {
						selectWindow("Results");
						IJ.renameResults(titlePostRW);
					} else if (isOpen(titlePostRW)) {
//						String.copyResults;
						CollateResults(titlePostRW, resultLabel);
					}
					roiManager("deselect");
//					roiManager("Save", destdir+ File.separator +nameSh+"PostDILRoiSet.zip");
//					selectWindow(LUPPost);
//					saveAs("tiff", destdir +File.separator+"Mask of "+PostCol+"-image Segmented");
//					LUPPost = LUPPost + ".tif";
					roiManager("Reset");
					if (ThrQ) {
						roiManager("Open", destdir+ File.separator +nameSh+"PreThrRoiSet.zip");
					} else roiManager("Open", destdir+ File.separator +nameSh+"PreALLRoiSet.zip");
					roiManager("Deselect");
					AssocROI(STRPost, STRPre, LUPPre, 0, StkQ, OverNo, PostMin);
					roiManager("deselect");
					roiManager("Save", destdir+ File.separator +nameSh+"PreSYNRoiSet.zip");
					selectWindow(STRPre);
					saveAs("tiff", destdir + File.separator +nameSh+"PreF.tif");
					rename(nameSh+"PreF.tif");
					PreC = roiManager("Count");
					ValuesPre = newArray(PreC);
					for (w = 0; w<PreC; w++) ValuesPre[w]=w+1;
					roiManager("Measure");
					SynPre[row] = nResults;
//					if (isOpen(titlePreRW)) {
//						String.copyResults;
//						print(titlePreRV, CopyResultsTable(resultLabel, false));
//					}

					saveAs("Measurements", exceldir+ File.separator +nameSh+"PreResults.txt");
					roiManager("Deselect");
					PreX = FillArray("X",PreC);
					PreY = FillArray("Y",PreC);
					PreXM = FillArray("XM",PreC);
					PreYM = FillArray("YM",PreC);
					PreID = FillArray("IntDen",PreC);
					PreResult = CopyResultsTableArr(resultLabel);
					ColorROI(PreC, dilateQ, dilatePx, LUPPre);
					if (!isOpen(titlePreRW)) {
						selectWindow("Results");
						IJ.renameResults(titlePreRW);
					} else if (isOpen(titlePreRW)) {
//						String.copyResults;
						CollateResults(titlePreRW, resultLabel);
					}
					roiManager("Reset");
					roiManager("Open", destdir+ File.separator +nameSh+"PreSynRoiSet.zip");
					MatchROI(ValuesPost, PostX, PostY, PostXM, PostYM, PostID, PostResult, LUPPost, PreX, PreY, PreXM, PreYM, PreResult, titleV);
					roiManager("Reset");
					roiManager("Open", destdir+ File.separator +nameSh+"PostSynRoiSet.zip");
					MatchROI(ValuesPre, PreX, PreY, PreXM, PreYM, PreID, PreResult, LUPPre, PostX, PostY, PostXM, PostYM, PostResult, titleX);
				} else {
				selectWindow(STRPost);
				saveAs("tiff", destdir + File.separator +nameSh+"PostF.tif");
				Syn[row] = 0;
				selectWindow(STRPre);
				run("Select All");
				run("Clear", "slice");
				run("Select None");
				saveAs("tiff", destdir + File.separator +nameSh+"PreF.tif");
				SynPre[row] = 0;
				}
			} else {
			selectWindow(STRPost);
			run("Select All");
			run("Clear", "slice");
			run("Select None");
			saveAs("tiff", destdir + File.separator +nameSh+"PostF.tif");
			Syn[row] = 0;
			selectWindow(STRPre);
			run("Select All");
			run("Clear", "slice");
			run("Select None");
			saveAs("tiff", destdir + File.separator +nameSh+"PreF.tif");
			SynPre[row] = 0;
			}
//			PreColor = "" + MatchUp(PreCol, Channels, Colors) + nameSh+"PreF.tif] ";
//			PreColor = "" + MatchUp(PreCol, Channels, Colors) + nameSh+"PreF.tif ";
			PreColor = "" + "c1=[" + nameSh+"PreF.tif] ";
//			selectWindow(nameSh+"PostF.tif");
//			print(PreColor);
//			PostColor = "" + MatchUp(PostCol, Channels, Colors) + nameSh+"PostF.tif] ";
//			PostColor = "" + MatchUp(PostCol, Channels, Colors) + nameSh+"PostF.tif ";
			PostColor = "" + "c2=[" + nameSh+"PostF.tif] ";
//			print(PostColor);
//			selectWindow(nameSh+"PreF.tif");
			run("Merge Channels...", PreColor + PostColor + "c3=C1-image c4=C2-image create keep ignore");
			selectWindow("Composite");
			saveAs("Tiff", mergedir+ File.separator +nameSh+"PrePost.tif");
			wait(50);
			row++;
			run("Close All Without Saving");
		}
	}
	run("Clear Results");
	for (x = 0; x < row; x++) {
		setResult("Label", x, LABEL[x]);
		setResult("Synapse Post No.", x, Syn[x]);
		setResult("Synapse Pre No.", x, SynPre[x]);
		if (ThrQ) setResult("Thr Pre No.", x, ThrPre[x]);
                        if (ForQ) setResult("Fourth Post No.", x, ForPost[x]);
		setResult("Post No.", x, Post[x]);
		setResult("Pre No.", x, Pre[x]);
  	}
	updateResults();
	selectWindow("Results");
	saveAs("Text", destdir+File.separator+"Collated ResultsIF.txt");
	if (isOpen(titlePreW)) {
		selectWindow(titlePreW);	
		saveAs("Text", destdir+ File.separator +titlePreW+".txt");
	}
	if (isOpen(titlePostW)) {
		selectWindow(titlePostW);
		saveAs("Text", destdir+ File.separator +titlePostW+".txt");
	}
	if (isOpen(titlePreRW)) {
		selectWindow(titlePreRW);
		saveAs("Text", destdir+ File.separator +titlePreRW+".txt");
	}
	if (isOpen(titlePostRW)) {
		selectWindow(titlePostRW);
		saveAs("Text", destdir+ File.separator +titlePostRW+".txt");
	}
	selectWindow(titleW);
	saveAs("Text", destdir+File.separator+"CorrResults.txt");
	selectWindow(titleU);
	saveAs("Text", destdir+File.separator+"CorrResults2.txt");
	selectWindow("Log");
	saveAs("Text", destdir+File.separator+"IFALog.txt");
	print("All finished...NEXT!!!");
}

function fadingCorr (IntArray, ChannelN) {
	Dialog.create(ChannelN + "Channel Fading Correction");
	for (f = 0; f< IntArray.length; f++) {
		Dialog.addNumber("Slice "+(f+1)+": ", IntArray[f]);
	}
	Dialog.show();
	for (g = 0; g<IntArray.length; g++) {
		IntArray[g] = Dialog.getNumber();
	}
	return IntArray;
}

function PrepChannel (ImName,ImNO, faded, IntMultiply, SubBKD, ImLOW, ImNOISE, ImSzLo, ImSzHi, D, DPX, B, BPX, StQx, FMax) {
	StQ = false;
	if (StQx == "stack") {
		StQ = true;
	}
	selectWindow(ImNO+"-image");
	if (B) {
		run("Median...", "radius="+BPX+" "+StQx);
	}
	if (faded) {
		for (m = 0; m<IntMultiply.length; m++) {
			setSlice(m+1);
			run("Multiply...", "value="+IntMultiply[m]+" slice");
		}
	}
	if (SubBKD != 0) {
		selectWindow(ImNO+"-image");
		run("Duplicate...", "title=["+ImNO+"-image-BKD] duplicate range=1-"+nSlices);
		selectWindow(ImNO+"-image");
		run("Subtract Background...", "rolling="+SubBKD+" "+StQx);
	}
//	run("Multiply...", "value=1000");
	if (FMax) {
		if (StQ) {
			imageName = ImNO+"-image";
			Maxima_Stack(imageName, ImLOW, ImNOISE, "Segmented Particles", false, false, true);
		} else {
			setThreshold(ImLOW,65535);
			run("Find Maxima...", "noise="+ImNOISE+" output=[Segmented Particles] above");
		}
		selectWindow(ImNO+"-image Segmented");
//	run("Invert LUT");
		selectWindow(ImNO+"-image Segmented");
		setAutoThreshold("Default dark");
		run("Analyze Particles...", "size="+ImSzLo+"-"+ImSzHi+" circularity=0.00-1.00 show=Masks "+StQx);
		selectWindow("Mask of "+ImNO+"-image Segmented");
		run("Invert LUT");
		run("16-bit");
		run("Multiply...", "value=257 "+StQx);
		run("Invert", StQx);
		if (SubBKD != 0) {
			selectWindow(ImNO+"-image");
			rename (ImNO+"-image+BKD");
			selectWindow(ImNO+"-image-BKD");
			rename (ImNO+"-image");
		}
		imageCalculator("Subtract create "+StQx, ImNO+"-image", "Mask of "+ImNO+"-image Segmented");
	} else {
		setThreshold(ImLOW,65535);
		run("Analyze Particles...", "size="+ImSzLo+"-"+ImSzHi+" circularity=0.00-1.00 show=Masks "+StQx);
		selectWindow("Mask of "+ImNO+"-image");
		run("Invert LUT");
		run("16-bit");
		run("Multiply...", "value=257 "+StQx);
		run("Invert", StQx);
		if (SubBKD != 0) {
			selectWindow(ImNO+"-image");
			rename (ImNO+"-image+BKD");
			selectWindow(ImNO+"-image-BKD");
			rename (ImNO+"-image");
		}
		imageCalculator("Subtract create "+StQx, ImNO+"-image", "Mask of "+ImNO+"-image");
	}
	selectWindow("Result of "+ImNO+"-image");
	setThreshold(ImLOW,65535);
	run("Analyze Particles...", "size="+ImSzLo+"-"+ImSzHi+" circularity=0.00-1.00 show=Nothing display clear summarize add "+StQx);
	if (FMax) {
		selectWindow("Mask of "+ImNO+"-image Segmented");
	} else selectWindow("Mask of "+ImNO+"-image");
	run("Invert", StQx);
	if (nResults >0) {
		if (D){
			if (FMax) {
				selectWindow("Mask of "+ImNO+"-image Segmented");
			} else selectWindow("Mask of "+ImNO+"-image");
			run("8-bit");
			if (StQ) {
				for (sl = 1; sl <=nSlices; sl++) {
					setSlice(sl);
					setAutoThreshold("Default dark");
					run("Create Selection");
					run ("Enlarge...", "enlarge="+DPX+" pixel");
					run("Set...", "value=255 slice");
				}
			} else {
				setAutoThreshold("Default dark");
				run("Create Selection");
				run("Enlarge...", "enlarge="+DPX+" pixel");
				run("Set...", "value=255");
			}
			run("16-bit");
			run("Multiply...", "value=257 "+StQx);
		}
		selectWindow("Results");
		for(n=0; n<nResults; n++) setResult("Label", n, ImName);
		updateResults();
	}
	return nResults;
}	

function Maxima_Stack (input, threshold, tolerance, MaximaType, exclude, light, above) {
  	selectWindow(input);
  	n = nSlices();
	options = "";
	if (exclude) options = options + " exclude";
  	if (light) {
		options = options + " light";
		if (above) print("Can't find minima on a thresholded image. Ignoring threshold request.");
	} else if (above) options = options + " above";
  	for (i=1; i<=n; i++) {
     		selectWindow(input);
     		setSlice(i);
		if (above) setThreshold(threshold, 4095);
		run("Find Maxima...", "noise="+tolerance+" output=["+MaximaType+"]"+options);
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
  	selectImage(output);
	rename (input+" Segmented");
}

function CopyResultsTableArr(Fields) {
  String.resetBuffer;
  ARRAYT = newArray(nResults);
  for (i=0; i<nResults; i++) {
     	for (j=0; j<Fields.length; j++) {
		if (j==0) String.append(getResultLabel(i));
		else String.append("\t" + getResult(Fields[j], i));
	}
	String.append("\t");
	ARRAYT[i] = String.buffer;
	String.resetBuffer;
  }
  return ARRAYT;
}

function CollateResults(ResultW, Fields) {
	NewResult = CopyResultsTableArr(Fields);
	selectWindow("Results");
	run("Close");
	selectWindow(ResultW);
	IJ.renameResults("Results");
	start = nResults;
	for (i=0; i<NewResult.length; i++) {
		p = i + start;
        	items=split(NewResult[i], cellseparator);
        	for (j=0; j<items.length; j++)
           		setResult(Fields[j],p,items[j]);
     	}
	updateResults();
	IJ.renameResults(ResultW);
}

function FillArray (Field, Num) {
	ARRAY = newArray(Num);
	for (k=0; k<Num; k++) ARRAY[k]=getResult(Field, k);
	return ARRAY;
}

function AssocROI (CheckIm, StoreIm, StoreImT, Hi, Stk, LapNo, CheckThresh){
//	if (Stk) SLST = "stack";
//	else SLST = "slice";
	SLST = "slice";
	if (LapNo > 1) {
		if (CheckThresh > 1) {
			selectWindow(CheckIm);
			setThreshold(CheckThresh, 65536);
			run("Analyze Particles...", "size=0-infinity show=[Count Masks] display clear stack");
			CheckIm = "Count Masks of "+CheckIm;
		} else {
			selectWindow(CheckIm);
			setThreshold(CheckThresh, 65536);
			run("Analyze Particles...", "size=0-infinity display clear stack");
		}
		EndVal = nResults + 1;
		HistVal = newArray(EndVal);
		for (v = 0; v < EndVal; v++) HistVal[v] = v;
		HistCt = newArray(EndVal);
		for (r = roiManager("Count")-1; r>= 0; r--) {
			selectWindow(CheckIm);
			roiManager("Select", r);
			roiManager("Measure");
			max = getResult("Max");
			if (max <= Hi) {
				selectWindow(StoreIm);
				roiManager("select", r);
				run("Clear", SLST);
				selectWindow(StoreImT);
				roiManager("select", r);
				run("Clear", SLST);
				roiManager("Delete");
			} else {
				roiManager("select", r);
				getHistogram(HistVal, HistCt, EndVal, 0, EndVal-1);
				DelROI = true;
				z = 1;
				do {
					if (HistCt[z] >= LapNo) DelROI = false;
					z++;
				} while (DelROI && z < EndVal);
				if (DelROI) {
					selectWindow(StoreIm);
					roiManager("select", r);
					run("Clear", SLST);
					selectWindow(StoreImT);
					roiManager("select", r);
					run("Clear", SLST);
					roiManager("Delete");
				}
			}
		}
	} else if (LapNo == 1) {
		for (r = roiManager("Count")-1; r>= 0; r--) {
			selectWindow(CheckIm);
			roiManager("Select", r);
			roiManager("Measure");
			max = getResult("Max");
			if (max <= Hi) {
				selectWindow(StoreIm);
				roiManager("select", r);
				run("Clear", SLST);
				selectWindow(StoreImT);
				roiManager("select", r);
				run("Clear", SLST);
				roiManager("Delete");
			}
		}
	}
	run("Clear Results");
}

function CoLocROI (CheckIm, StoreIm, StoreIm2, Hi, Lo, Sz, Stk){
//	if (Stk) SLST = "stack";
//	else SLST = "slice";
	SLST = "slice";
	for (r = roiManager("Count")-1; r>= 0; r--) {
		selectWindow(CheckIm);
		roiManager("Select", r);
		roiManager("Measure");
		max = getResult("Max");
		min = getResult("Min");
		if (max <= Hi || min <= Lo) {
			selectWindow(StoreIm);
			roiManager("select", r);
			run("Clear", SLST);
			selectWindow(StoreIm2);
			roiManager("select", r);
			run("Clear", SLST);
			roiManager("Delete");
		}
	}
	run("Clear Results");
}

function ColorROI (Numb, DQ, DPIX, ImCol) {
	if (Numb > 65534) {
		selectWindow(ImCol);
		run("32-bit");
	}
	roiManager("Deselect");
	for (l = 0; l < Numb; l++) {
		FCol = l+1;
		if (DQ) {
			roiManager("Select", l);
			run("Enlarge...", "enlarge="+DPIX+" pixel");
			roiManager("Update");
			run("Select None");
		}
		selectWindow(ImCol);
		roiManager("Select", l);
		run("Set...", "value="+FCol);
		roiManager("Deselect");
	}
}

function MatchROI (HistV, VX, VY, VXM, VYM, VID, VResult, VWindow, ROIX, ROIY, ROIXM, ROIYM, ROIResult, OutWindow) {
	SLST = "slice";
	VC = HistV.length;
	ROIC = roiManager("Count");
	hmin= HistV[0];
	hmax=HistV[VC-1];
	for (m = 0; m < ROIC; m++) {
		lineP = "";
		histoROI = newArray(hmax-hmin); 
		roiManager("Deselect");
		selectWindow(VWindow);
		roiManager("Select", m);
		getHistogram(HistV, histoROI, VC, hmin, hmax);
		VPerROI = 0;
		VIDPerROI = 0;
		distSm = 0;
		VStar = -1;
		for (n = 0; n < VC; n++) {
			if (histoROI[n] > 0) {
				dist = sqrt(pow(ROIX[m]-VX[n],2) + pow(ROIY[m]-VY[n],2));
				distM = sqrt(pow(ROIXM[m]-VXM[n],2) + pow(ROIYM[m]-VYM[n],2));				
			if (dist <  distSm || distSm ==0) {
					lineP ="\t"+ n +"\t"+ histoROI[n] +"\t"+d2s(dist,3)+"\t"+d2s(distM,3) + lineP;
					distSm = dist;
					VStar = n;
				} else if (dist >= distSm) {
					lineP =lineP+"\t"+ n +"\t"+ histoROI[n] +"\t"+d2s(dist,3)+"\t"+d2s(distM,3);
				}
				VPerROI = VPerROI + 1;
				VIDPerROI = VIDPerROI + VID[n];
			}
		}
		if (VStar != -1) {
			lineP = ROIResult[m]+VResult[VStar]+VPerROI+"\t"+VIDPerROI+lineP + "\n";
			print(OutWindow, lineP);
		} 
	}
}

function MatchUp(Item, ArrayOrig, ArrayNew) {
	for (p=0;p<ArrayNew.length; p++) {
//		print(p, Item, ArrayOrig[p], ArrayNew[p]);
		if (Item == ArrayOrig[p]) STAR = ArrayNew[p];
	}
	return STAR;
}

function getScaleAndUnit() {
      selectImage(getImageID);
      info = getInfo();
      index1 = indexOf(info, "Resolution: ");
      if (index1==-1)
          {scale=1; unit = "pixel"; return;}          
      index2 = indexOf(info, "\n", index1);
      line = substring(info, index1+12, index2);
      words = split(line, "");
      scale = 0+words[0];
      unit = words[3];
}


