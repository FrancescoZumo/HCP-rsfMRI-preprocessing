#!/bin/bash

#keep it updated!
usage (){
	printf "\nUsage: script

Optional arguments

-p, --path
\tSet a different path to data\n

-h, --help
\tShows usage\n"
}

#Default path to HCP data 
PATH2DATA="../Data"

#optional arguments
while [[ "$1" != "" ]]; do
	case $1 in
		-p | --path )
			shift
			PATH2DATA=$1
			;;
		-h | --help )
			usage
			exit
			;;
		* )
			echo "Unknown option, Abort"
			exit
			;;
	esac
	shift
done

#variable for storing the previous and the current subject checked
current=""
prev=""

#creating a folder for each subject
for entry in "$PATH2DATA"/*; do
	entry=${entry#"$PATH2DATA/"}
	current=${entry:0:6}
	# here I assume that the for cycle orders entries by name, 
	# so I will always get folders from the same subject consecutively
	if [[ $current != $prev ]]; then
		# I store a new subject only if the previous is different
		mkdir $PATH2DATA/$current
	fi
	mv $PATH2DATA/$entry $PATH2DATA/$current
	prev=$current
done

#commenta molto tutto il codice, spiega parametri scelti x ogni comando e perché lo stai facendo

#repeating all processing for each subject found in Data folder
for subject in "$PATH2DATA"/*; do
	id=${subject#"$PATH2DATA/"}
	PATH2RES="$subject/results"
	rfMRI=$id_
	mkdir $subject/results

	#saving the path for each file that will be used
	SBRef_dc_T1w="$subject/${id}_3T_rfMRI_REST1_preproc/$id/T1w/Results/rfMRI_REST1_LR/SBRef_dc.nii.gz"
	rfMRI_REST1_LR_SBRef="$subject/${id}_3T_rfMRI_REST1_preproc/$id/MNINonLinear/Results/rfMRI_REST1_LR/rfMRI_REST1_LR_SBRef.nii.gz"
	SBRef_dc="$subject/${id}_3T_rfMRI_REST1_preproc/$id/MNINonLinear/Results/rfMRI_REST1_LR/SBRef_dc.nii.gz"
	T1w_acpc_dc_restore="$subject/${id}_3T_Structural_preproc/$id/T1w/T1w_acpc_dc_restore.nii.gz"

	#brain extraction

	#these images contain whole head, I need to extract the brain for next operations (epi_reg, applyXFM)
	printf "\nbet $SBRef_dc $PATH2RES/SBRef_dc_brain.nii.gz -R -f 0.65\n"
	# for each bet, after som trials, I selected the best -f value
	bet $SBRef_dc $PATH2RES/SBRef_dc_brain.nii.gz -R -f 0.65
	printf "\nbet $SBRef_dc_T1w $PATH2RES/SBRef_dc_T1w_brain.nii.gz -R -f 0.5\n"
	bet $SBRef_dc_T1w $PATH2RES/SBRef_dc_T1w_brain.nii.gz -R -f 0.5
	printf "\nbet $T1w_acpc_dc_restore $PATH2RES/T1w_acpc_dc_restore_brain.nii.gz -R -f 0.2\n"
	bet $T1w_acpc_dc_restore $PATH2RES/T1w_acpc_dc_restore_brain.nii.gz -R -f 0.2

	#flirt
	#phase one: I want to match the SBRef file from fmri (res=2mm) with the one from sructural space (res=0.7mm)
	#parameters: 12 dof, images: already virtually aligned, cost function: normalized mutual information
	#
	printf "\nflirt -in $PATH2RES/SBRef_dc_brain.nii.gz -ref $PATH2RES/SBRef_dc_T1w_brain.nii.gz -out $PATH2RES/flirt -omat $PATH2RES/flirt.mat -bins 256 -cost normmi -searchrx 0 0 -searchry 0 0 -searchrz 0 0 -dof 12  -interp trilinear\n"
	flirt -in $PATH2RES/SBRef_dc_brain.nii.gz -ref $PATH2RES/SBRef_dc_T1w_brain.nii.gz -out $PATH2RES/flirt -omat $PATH2RES/flirt.mat -bins 256 -cost normmi -searchrx 0 0 -searchry 0 0 -searchrz 0 0 -dof 12  -interp trilinear

	#epi_reg
	#phase two: I want to 
	printf "\nepi_reg --epi=$PATH2RES/SBRef_dc_T1w_brain.nii.gz --t1=$T1w_acpc_dc_restore --t1brain=$PATH2RES/T1w_acpc_dc_restore_brain.nii.gz --out=$PATH2RES/epi2struct\n"
	epi_reg --epi=$PATH2RES/SBRef_dc_T1w_brain.nii.gz --t1=$T1w_acpc_dc_restore --t1brain=$PATH2RES/T1w_acpc_dc_restore_brain.nii.gz --out=$PATH2RES/epi2struct

	#Concatxfm
	printf "\nconvert_xfm -omat $PATH2RES/finalMatrix.mat -concat $PATH2RES/epi2struct.mat $PATH2RES/flirt.mat \n"
	convert_xfm -omat $PATH2RES/finalMatrix.mat -concat $PATH2RES/epi2struct.mat $PATH2RES/flirt.mat 

	#metti questa, sopra ho scambiato e dovrebbe essere giusto, controlla x sicurezza
	#convert_xfm -omat finedef -concat /home/francescozumo/Desktop/working_folder/epi2struct.mat /home/francescozumo/Desktop/working_folder/flirt.mat

	#ApplyXFM
	#contrplla senza percorso assoluto
	printf "\nflirt -in $rfMRI_REST1_LR_SBRef -applyxfm -init $PATH2RES/finalMatrix.mat -out $PATH2RES/rfMRI_REST1_LR_SBRef_matApplied -paddingsize 0.0 -interp trilinear -ref $PATH2RES/T1w_acpc_dc_restore_brain.nii.gz\n"
	flirt -in $rfMRI_REST1_LR_SBRef -applyxfm -init $PATH2RES/finalMatrix.mat -out $PATH2RES/rfMRI_REST1_LR_SBRef_matApplied -paddingsize 0.0 -interp trilinear -ref $PATH2RES/T1w_acpc_dc_restore_brain.nii.gz

	#da aggiungere
	#fast T1w_acpc_dc_restore_brain.nii.gz

	#convert_xfm -omat $PATH2RES/inverseMatrix.mat -inverse $PATH2RES/finalMatrix.mat

	

done