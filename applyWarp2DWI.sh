#! /bin/bash

#########################################################################################################################
#########################################################################################################################
###################                                                                                   ###################
###################     title:                      Apply ANTs Warp/Affine to DWIs                    ###################
###################                                                                                   ###################
###################     description:    Script for applying warp/affine to DWI images                 ################### 
###################     version:        0.0.0.0                                                       ###################
###################     notes:          Install MRtrix 3, ANTs, FSL to use this script                ###################
###################     bash version:   tested on GNU bash, version  4.2.53                           ###################
###################                                                                                   ###################
###################     autor: gamorosino                                                             ###################
###################     email: g.amorosino@gmail.com                                                  ###################
###################                                                                                   ###################
#########################################################################################################################
#########################################################################################################################

SCRIPT=`realpath -s $0`
scriptdir=`dirname $SCRIPT`

remove_ext () {

	#   based on remove_ext function from FSL - FMRIB's Software Library
	#	http://www.fmrib.ox.ac.uk/fsl
	#


	local lst="";
	for fn in $@ ; do
		# for the ones at the end of the line
		local f=`echo "$fn" | sed 's/\.hdr\.gz$//' | sed 's/\.img\.gz$//' | sed 's/\.hdr$//' | sed 's/\.img$//' | sed 's/\.nii.gz$//' | sed 's/\.nii$//' | sed 's/\.mnc.gz$//' | sed 's/\.mnc$//' | sed 's/\.$//'`;
			# for the ones in the middle of the line
		local f=`echo "$f" | sed 's/\.hdr\.gz[ 	]/ /g' | sed 's/\.img\.gz[ 	]/ /g' | sed 's/\.hdr[ 	]/ /g' | sed 's/\.img[ 	]/ /g' | sed 's/\.nii\.gz[ 	]/ /g' | sed 's/\.nii[ 	]/ /g' | sed 's/\.mnc\.gz[ 	]/ /g' | sed 's/\.mnc[ 	]/ /g' |sed 's/\.[ 	]/ /g'`;
		local lst="$lst $f";
	done
	echo $lst;
}

fextension () {
                ############# ############# ############# ############# ############# ############# 
                #############   	Estrae l'estenzione dal nome di un file       ############# 
                ############# ############# ############# ############# ############# #############  
                
                local filename=$( basename $1 )
                local extension="${filename##*.}"
		echo $extension
		
		};

exists () {
                ############# ############# ############# ############# ############# ############# #############
                #############  		      Controlla l'esistenza di un file o directory	    ############# 
                ############# ############# ############# ############# ############# ############# #############  		                      			
		if [ $# -lt 1 ]; then
		    echo $0: "usage: exists <filename> "
		    echo "    echo 1 if the file (or folder) exists, 0 otherwise"
		    return 1;		    
		fi 
		
		if [ -d "${1}" ]; then 

			echo 1;
		else
			([ -e "${1}" ] && [ -f "${1}" ]) && { echo 1; } || { echo 0; }	
		fi		
		};


fbasename () {
                ############# ############# ############# ############# ############# ############# 
                #############   Rimuone directory ed estenzione dal nome di un file   ############# 
                ############# ############# ############# ############# ############# #############
                  
                echo ` basename $1 | cut -d '.' -f 1 `
		
		};

if [ $# -lt 6 ]; then							# usage dello script							
	    echo : "usage: "$( basename $0 )" <moving.ext> <bvals.ext> <bvecs.ext> <fixed.ext> <affine.mat> <warp.ext> [<file_out.ext>] [compute_DT_scalars] [<pre_affine.mat>]"
	    exit 1;		    
fi 
			
moving=$1
echo "moving: " $moving
bvals=$2
echo "bvals: " $bvals
bvecs=$3
echo "bvecs: " $bvecs
fixed=$4	
echo "fixed: " $fixed
affine=$5
echo "affine: " $affine
warp=$6
echo "warpField: " $warp
output_nii=$7
echo "output: " $output_nii
compute_DT_Scalars=$8
echo "compute_DT_Scalars: " $compute_DT_Scalars
affine1=$9
echo "pre-affine: " $affine1

[ -z ${compute_DT_Scalars} ] && { compute_DT_Scalars=0 ; }

warp_cmd=''
[ ${warp} == "None" ] || { warp_cmd="-t ${warp}" ;}

#0. Generate an identity (deformation field) warp using the image you wish to warp (“source”; or “moving” image):
#.mif
warpinit ${moving} identity_warp[].nii -force

#1. ansform this identity warp using the registration program that was used to generate the warp.
#For example, if you are using the ANTs registration package:

#2.Transform this identity warp using the registration program that was used to generate the warp.

#for i in {0..2}; do
#    antsApplyTransforms -d 3 -e 0 -i identity_warp${i}.nii -o mrtrix_warp${i}.nii -r ${fixed} -t ${warp} -t [${affine},1] #--default-value 2147483647
#done

[ -z ${affine1} ] || { pre_affine=" -t [${affine1},1]  " ; }

for i in {0..2}; do
    antsApplyTransforms -d 3 -e 0 -i identity_warp${i}.nii -o mrtrix_warp${i}.nii -r ${fixed} ${warp_cmd}  -t ${affine}  ${pre_affine}   #--default-value 2147483647
done

#3. Correct the warp

warpcorrect mrtrix_warp[].nii mrtrix_warp_corrected.mif -force #-marker 2147483647

#4. Warp the image

#mrtransform input.nii -warp mrtrix_warp_corrected.mif warped_input_image.mif

moving_ext=$( fextension $moving )

if ( [ "${moving_ext}" == "nii"  ] || [ "${moving_ext}" == "gz" ] ); then

	moving_mif=$( remove_ext ${moving} ).mif

	[ $( exists ${moving_mif} ) -eq 0 ]  && { mrconvert ${moving} ${moving_mif} -fslgrad ${bvecs} ${bvals} -force ; }

elif  [ "${moving_ext}" == "mif"  ]; then

	moving_mif=$moving

fi


[ -z ${output_nii} ] && { output_nii=$( remove_ext ${moving} )_warped.nii ; }
output_mif=$( remove_ext ${output_nii} )_warped.mif

bvecs_warped=$( remove_ext ${output_nii} ).bvecs
bvals_warped=$( remove_ext ${output_nii} ).bvals

[ $( exists ${output_mif} ) -eq 0 ]  && { mrtransform ${moving_mif} ${output_mif} -warp mrtrix_warp_corrected.mif -force ; } # -fslgrad  ${bvecs} ${bvals}  #-export_grad_fsl ${bvecs_warped} ${bvals_warped}

( [ $( exists ${output_nii} ) -eq 0 ] || [ $( exists ${bvecs_warped} ) -eq 0 ] || [ $( exists ${bvals_warped} ) -eq 0 ] )  \
						&& { mrconvert ${output_mif}  ${output_nii} -export_grad_fsl  ${bvecs_warped} ${bvals_warped} -force ; }
