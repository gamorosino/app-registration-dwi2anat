#! /bin/bash

#########################################################################################################################
#########################################################################################################################
###################                                                                                   ###################
###################     title:                      Apply ANTs Warp/Affine to DWIs                    ###################
###################                                                                                   ###################
###################     description:    Script for applying warp/affine to DWI images                 ################### 
###################     version:        0.0.2.0                                                       ###################
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

[ $( exists ${output_mif} ) -eq 0 ]  && { mrtransform ${moving_mif} ${output_mif} -warp mrtrix_warp_corrected.mif -force  -reorient_fod no ; } # -fslgrad  ${bvecs} ${bvals}  #-export_grad_fsl ${bvecs_warped} ${bvals_warped}

tmp_bvecs=${bvecs_warped}.tmp

mrconvert ${output_mif} ${output_nii} \
    -export_grad_fsl ${tmp_bvecs} ${bvals_warped} \
    -force

echo "DEBUG affine path: ${affine}"

mkdir -p ./temp

echo "Converting affine to plain text..."

singularity exec -e docker://brainlife/ants:2.2.0-1bc \
    ConvertTransformFile 3 \
    ${affine} \
    ./temp/affine.txt

echo "DEBUG converted affine:"
cat ./temp/affine.txt

python << EOF

import numpy as np
import os

affine_path = "./temp/affine.txt"
bvecs_path = "${tmp_bvecs}"
out_path = "${bvecs_warped}"

print("Reading affine:", affine_path)
print("Reading bvecs:", bvecs_path)

# load bvecs
bvecs = np.loadtxt(bvecs_path)

if bvecs.shape[0] != 3 and bvecs.shape[1] == 3:
    bvecs = bvecs.T

if bvecs.shape[0] != 3:
    raise RuntimeError("Expected bvecs shape 3 x N, got: " + str(bvecs.shape))

# read affine
vals = None

with open(affine_path, "r") as f:
    for line in f:
        line = line.strip()

        if line.startswith("Parameters:"):
            vals = [float(x) for x in line.split()[1:10]]
            break

if vals is None:
    raise RuntimeError("Could not find affine parameters")

A = np.array(vals).reshape(3,3)

print("Affine matrix:")
print(A)

# extract pure rotation
U, s, Vt = np.linalg.svd(A)
R = np.dot(U, Vt)

# fix reflection if needed
if np.linalg.det(R) < 0:
    U[:, -1] *= -1
    R = np.dot(U, Vt)

print("Rotation matrix:")
print(R)

# rotate bvecs
bvecs_rot = np.dot(R, bvecs)

# normalize
norms = np.linalg.norm(bvecs_rot, axis=0)
mask = norms > 1e-6

bvecs_rot[:, mask] /= norms[mask]
bvecs_rot[:, ~mask] = 0.0

# save
np.savetxt(out_path, bvecs_rot, fmt="%.10f")

print("Rotated bvecs written to:", out_path)

EOF
rm ${tmp_bvecs}
rm ${output_mif}


