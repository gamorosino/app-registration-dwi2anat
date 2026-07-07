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
qc_wm=${10}
echo "qc_wm: " $qc_wm

[ -z ${compute_DT_Scalars} ] && { compute_DT_Scalars=0 ; }
[ -z ${qc_wm} ] && { qc_wm=false ; }

warp_cmd=''
[ “${warp}” = “None” ] || { warp_cmd=”-t ${warp}” ; }

mkdir -p ./work

#0. Generate an identity (deformation field) warp using the image you wish to warp (“source”; or “moving” image):
warpinit ${moving} ./work/identity_warp[].nii -force

#1. Transform this identity warp using the registration program that was used to generate the warp.
#2. Apply ANTs transforms to each identity warp component.

[ -z ${affine1} ] || { pre_affine=” -t [${affine1},1]  “ ; }

for i in {0..2}; do
    antsApplyTransforms -d 3 -e 0 -i ./work/identity_warp${i}.nii -o ./work/mrtrix_warp${i}.nii -r ${fixed} ${warp_cmd}  -t ${affine}  ${pre_affine}
done

#3. Correct the warp

warpcorrect ./work/mrtrix_warp[].nii ./work/mrtrix_warp_corrected.mif -force

#4. Warp the image

#mrtransform input.nii -warp mrtrix_warp_corrected.mif warped_input_image.mif

moving_ext=$( fextension $moving )

if ( [ "${moving_ext}" == "nii"  ] || [ "${moving_ext}" == "gz" ] ); then

	moving_mif=./work/$( fbasename ${moving} ).mif

	[ $( exists ${moving_mif} ) -eq 0 ]  && { mrconvert ${moving} ${moving_mif} -fslgrad ${bvecs} ${bvals} -force ; }

elif  [ "${moving_ext}" == "mif"  ]; then

	moving_mif=$moving

fi


[ -z ${output_nii} ] && { output_nii=$( remove_ext ${moving} )_warped.nii ; }
output_mif=$( remove_ext ${output_nii} )_warped.mif

bvecs_warped=$( remove_ext ${output_nii} ).bvecs
bvals_warped=$( remove_ext ${output_nii} ).bvals

[ $( exists ${output_mif} ) -eq 0 ]  && { mrtransform ${moving_mif} ${output_mif} -warp ./work/mrtrix_warp_corrected.mif -force  -reorient_fod no ; } # -fslgrad  ${bvecs} ${bvals}  #-export_grad_fsl ${bvecs_warped} ${bvals_warped}

tmp_bvecs=${bvecs_warped}.tmp

mrconvert ${output_mif} ${output_nii} \
    -export_grad_fsl ${tmp_bvecs} ${bvals_warped} \
    -force

echo "DEBUG affine path: ${affine}"

echo "Converting affine to plain text..."

ConvertTransformFile 3 \
    ${affine} \
    ./work/affine.txt

echo "DEBUG converted affine:"
cat ./work/affine.txt

python << EOF

import numpy as np
import os

affine_path = "./work/affine.txt"
bvecs_path = "${tmp_bvecs}"
out_path = "${bvecs_warped}"

print("Reading affine:", affine_path)
print("Reading bvecs:", bvecs_path)
print("Writing default output:", out_path)

bvecs = np.loadtxt(bvecs_path)

if bvecs.shape[0] != 3 and bvecs.shape[1] == 3:
    bvecs = bvecs.T

if bvecs.shape[0] != 3:
    raise RuntimeError("Expected bvecs shape 3 x N, got: " + str(bvecs.shape))

vals = None

with open(affine_path, "r") as f:
    for line in f:
        line = line.strip()
        if line.startswith("Parameters:"):
            vals = [float(x) for x in line.split()[1:10]]
            break

if vals is None:
    raise RuntimeError("Could not find affine parameters")

A = np.array(vals).reshape(3, 3)

print("Affine matrix (ITK/LPS):")
print(A)

# ANTs/ITK matrix is in LPS physical space; FSL bvecs are in RAS frame.
# Conjugate into RAS before extracting the rotation.
lps2ras = np.diag([-1., -1., 1.])
A_ras = lps2ras @ A @ lps2ras

print("Affine matrix (RAS):")
print(A_ras)

U, s, Vt = np.linalg.svd(A_ras)
R = np.dot(U, Vt)

if np.linalg.det(R) < 0:
    U[:, -1] *= -1
    R = np.dot(U, Vt)

print("Rotation matrix:")
print(R)
print("det(R):", np.linalg.det(R))

def normalize_bvecs(B):
    norms = np.linalg.norm(B, axis=0)
    mask = norms > 1e-6
    B[:, mask] /= norms[mask]
    B[:, ~mask] = 0.0
    return B

bvecs_R  = normalize_bvecs(np.dot(R, bvecs))
bvecs_RT = normalize_bvecs(np.dot(R.T, bvecs))

np.savetxt("./work/rotated_R.bvecs",  bvecs_R,  fmt="%.10f")
np.savetxt("./work/rotated_RT.bvecs", bvecs_RT, fmt="%.10f")

# ANTs stores T: fixed(T1) -> moving(DWI)  [ITK pull convention].
# The rotation physically applied to the DWI image to reach T1 space is R^T (= R^{-1}).
# Bvecs must follow the same rotation.
np.savetxt(out_path, bvecs_RT, fmt="%.10f")

### --- algebraic sanity checks (always run, no image-grid dependency) ---

# 1. det(R) must be exactly +1
det = np.linalg.det(R)
assert abs(det - 1.0) < 1e-6, "det(R) != 1 — R is not a proper rotation matrix"

# 2. Round-trip: R @ R^T @ bvecs_orig should recover the original bvecs
recovered = R @ bvecs_RT
mask = np.linalg.norm(bvecs, axis=0) > 1e-6
cos  = np.einsum('ij,ij->j', recovered[:,mask], bvecs[:,mask]) / (
       np.linalg.norm(recovered[:,mask],axis=0) * np.linalg.norm(bvecs[:,mask],axis=0))
roundtrip_err = float(np.degrees(np.arccos(np.clip(cos,-1,1))).max())
assert roundtrip_err < 0.0001, f"Round-trip error {roundtrip_err:.6f} deg — rotation not self-consistent"
print(f"Sanity check PASS — round-trip error: {roundtrip_err:.8f} deg")

# 3. Print Euler XYZ angles for visual confirmation against the registered image
RT = R.T
beta  = np.degrees(np.arcsin(np.clip(-RT[2,0], -1, 1)))
alpha = np.degrees(np.arctan2(RT[2,1], RT[2,2]))
gamma = np.degrees(np.arctan2(RT[1,0], RT[0,0]))
print(f"Rotation applied to bvecs (R^T) — Euler XYZ (intrinsic):")
print(f"  Rx L-R  (pitch): {alpha:.2f} deg")
print(f"  Ry A-P  (roll ): {beta:.2f} deg")
print(f"  Rz I-S  (yaw  ): {gamma:.2f} deg")

print("Saved:")
print("./work/rotated_R.bvecs")
print("./work/rotated_RT.bvecs")
print("Pipeline bvecs written to:", out_path)

EOF
rm ${tmp_bvecs}
rm ${output_mif}

### === QC: edge-overlay registration check ===

mkdir -p ./QC

python3 << PYEOF

import numpy as np
import nibabel as nib
import nibabel.orientations as nio
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from scipy.ndimage import sobel, gaussian_filter, center_of_mass, affine_transform
import os

qc_wm = "${qc_wm}".lower() in ("true", "1", "yes")

# ── load images ──────────────────────────────────────────────────────────────
fixed_img  = nib.load("${fixed}")
moved_img  = nib.load("${output_nii}")

fixed_data = fixed_img.get_fdata(dtype=np.float32)
moved_data = moved_img.get_fdata(dtype=np.float32)

# extract b0 (first minimum-bval volume)
bvals_arr = np.loadtxt("${bvals_warped}")
b0_idx    = int(np.argmin(bvals_arr))
moved_b0  = moved_data[..., b0_idx] if moved_data.ndim == 4 else moved_data

# ── resample b0 onto T1 grid via world-space affines ─────────────────────────
M = np.linalg.inv(moved_img.affine) @ fixed_img.affine
b0_r = affine_transform(moved_b0, M[:3, :3], offset=M[:3, 3],
                        output_shape=fixed_data.shape, order=1, cval=0.0)

# ── normalise and edge-detect ─────────────────────────────────────────────────
def normalize(v):
    p2, p98 = np.percentile(v[v > 0], [2, 98])
    return np.clip((v - p2) / (p98 - p2 + 1e-9), 0, 1)

def make_edges(v, sigma=1.5):
    s   = gaussian_filter(v.astype(np.float32), sigma=sigma)
    mag = np.sqrt(sobel(s, 0)**2 + sobel(s, 1)**2 + sobel(s, 2)**2)
    return (mag > np.percentile(mag[mag > 0], 85)).astype(np.float32)

# ── reorient to RAS canonical for standard display ───────────────────────────
# guarantees neurological convention (L-left, S-top) regardless of input orientation
def to_ras(data, affine):
    ornt = nio.io_orientation(affine)
    tgt  = nio.axcodes2ornt(('R', 'A', 'S'))
    return nio.apply_orientation(data, nio.ornt_transform(ornt, tgt))

fn_ras  = to_ras(normalize(fixed_data), fixed_img.affine)
be_ras  = to_ras(make_edges(normalize(b0_r)), fixed_img.affine)
b0_ras  = to_ras(b0_r, fixed_img.affine)

# ── centre-of-mass slices in RAS space ───────────────────────────────────────
cx, cy, cz = [int(round(c)) for c in
              center_of_mass(b0_ras > np.percentile(b0_ras[b0_ras > 0], 30))]
cx = np.clip(cx, 0, fn_ras.shape[0]-1)
cy = np.clip(cy, 0, fn_ras.shape[1]-1)
cz = np.clip(cz, 0, fn_ras.shape[2]-1)

# ── slice helper: neurological convention (L-left, S/A at top) ───────────────
# RAS axes: 0=R, 1=A, 2=S
# flip first axis (R) so L is on left; transpose; flipud so S/A is on top
def show_slice(vol, axis, idx):
    s = vol[:, :, idx] if axis == 2 else (vol[:, idx, :] if axis == 1 else vol[idx, :, :])
    return np.flipud(s[::-1, :].T)

# ── load original (pre-registration) DWI b0 and resample to T1 grid ──────────
orig_img   = nib.load("${moving}")
orig_data  = orig_img.get_fdata(dtype=np.float32)
orig_bvals = np.loadtxt("${bvals}")
orig_b0    = orig_data[..., int(np.argmin(orig_bvals))] if orig_data.ndim == 4 else orig_data

M_orig    = np.linalg.inv(orig_img.affine) @ fixed_img.affine
b0_orig_r = affine_transform(orig_b0, M_orig[:3, :3], offset=M_orig[:3, 3],
                             output_shape=fixed_data.shape, order=1, cval=0.0)

be_orig_ras = to_ras(make_edges(normalize(b0_orig_r)), fixed_img.affine)

# ── optional: WM masks via independent DTI fits ──────────────────────────────
# Before: fit on original DWI (native space) → resample mask to T1 grid
# After:  fit on registered DWI (already in T1-aligned space) → resample mask to T1 grid
wm_before_ras = None
wm_after_ras  = None
if qc_wm:
    try:
        from dipy.core.gradients import gradient_table
        from dipy.reconst.dti import TensorModel

        def fit_wm_mask(data, bvals_path, bvecs_path, aff, fixed_aff, fixed_shape, fa_thr=0.35):
            bv  = np.loadtxt(bvals_path)
            bvc = np.loadtxt(bvecs_path).T      # dipy expects N×3
            gtab = gradient_table(bv, bvc, b0_threshold=100)
            FA   = np.nan_to_num(TensorModel(gtab).fit(data).fa,
                                 nan=0.0, posinf=0.0, neginf=0.0)
            mask = (FA >= fa_thr).astype(np.float32)
            Mw   = np.linalg.inv(aff) @ fixed_aff
            mask_r = affine_transform(mask, Mw[:3, :3], offset=Mw[:3, 3],
                                      output_shape=fixed_shape, order=0, cval=0.0)
            return to_ras(mask_r, fixed_aff)

        print("Fitting DTI on original DWI...")
        wm_before_ras = fit_wm_mask(orig_data, "${bvals}", "${bvecs}",
                                    orig_img.affine, fixed_img.affine, fixed_data.shape)
        print(f"  WM voxels (Before, FA>=0.35): {int(wm_before_ras.sum())}")

        print("Fitting DTI on registered DWI...")
        wm_after_ras  = fit_wm_mask(moved_data, "${bvals_warped}", "${bvecs_warped}",
                                    moved_img.affine, fixed_img.affine, fixed_data.shape)
        print(f"  WM voxels (After,  FA>=0.35): {int(wm_after_ras.sum())}")

    except Exception as e:
        print(f"Warning: WM mask skipped — {e}")
        wm_before_ras = wm_after_ras = None

# ── shared render helper ──────────────────────────────────────────────────────
wm_suffix  = " + WM FA≥0.35 (blue)" if wm_after_ras is not None else ""
wm_per_row = [(be_orig_ras, "Before", wm_before_ras),
              (be_ras,      "After",  wm_after_ras)]

def render_panel(ax, axis, idx, edges_vol, row_label, wm_vol):
    bg = show_slice(fn_ras,    axis, idx)
    fg = show_slice(edges_vol, axis, idx)
    ax.imshow(bg, cmap="gray", vmin=0, vmax=1, interpolation="bilinear")
    rgba = np.zeros((*fg.shape, 4), dtype=np.float32)
    rgba[..., 0] = 1.0; rgba[..., 1] = 0.55; rgba[..., 2] = 0.0
    rgba[..., 3] = fg * 0.85
    ax.imshow(rgba, interpolation="nearest")
    if wm_vol is not None:
        wm_sl = show_slice(wm_vol, axis, idx)
        rgba_wm = np.zeros((*wm_sl.shape, 4), dtype=np.float32)
        rgba_wm[..., 2] = 1.0
        rgba_wm[..., 3] = wm_sl * 0.55
        ax.imshow(rgba_wm, interpolation="nearest")
    ax.axis("off")

os.makedirs("./QC", exist_ok=True)

# ── 1. orthoview_qc.png — 2×3 summary (one slice per plane) ─────────────────
view_labels = ["Axial", "Coronal", "Sagittal"]
axes_idx    = [2, 1, 0]
slices_idx  = [cz, cy, cx]

fig, axs = plt.subplots(2, 3, figsize=(15, 10), facecolor="black")
fig.suptitle(f"Registration QC — T1 (grey) + DWI-b0 edges (orange){wm_suffix}",
             color="white", fontsize=14)
for col, (label, axis, idx) in enumerate(zip(view_labels, axes_idx, slices_idx)):
    for row, (edges_vol, row_label, wm_vol) in enumerate(wm_per_row):
        render_panel(axs[row, col], axis, idx, edges_vol, row_label, wm_vol)
        axs[row, col].set_title(f"{row_label} — {label}", color="white", fontsize=11)
plt.tight_layout()
plt.savefig("./QC/orthoview_qc.png", dpi=150, bbox_inches="tight", facecolor="black")
plt.close()
print("QC image saved to: ./QC/orthoview_qc.png")

# ── 2. per-plane multi-slice QC (5 slices at 25/35/50/65/75 %) ───────────────
FRACS  = [0.25, 0.35, 0.50, 0.65, 0.75]
PLANES = [
    ("axial",    2, fn_ras.shape[2]),
    ("coronal",  1, fn_ras.shape[1]),
    ("sagittal", 0, fn_ras.shape[0]),
]

for plane_name, axis, dim in PLANES:
    idxs = [int(round(f * (dim - 1))) for f in FRACS]
    pcts = [int(round(f * 100)) for f in FRACS]
    fig, axs = plt.subplots(2, len(idxs), figsize=(5 * len(idxs), 8), facecolor="black")
    fig.suptitle(f"Registration QC — {plane_name.capitalize()} slices — "
                 f"T1 (grey) + DWI-b0 edges (orange){wm_suffix}",
                 color="white", fontsize=13)
    for col, (idx, pct) in enumerate(zip(idxs, pcts)):
        for row, (edges_vol, row_label, wm_vol) in enumerate(wm_per_row):
            render_panel(axs[row, col], axis, idx, edges_vol, row_label, wm_vol)
            axs[row, col].set_title(f"{row_label} — {pct}%",
                                    color="white", fontsize=10)
    plt.tight_layout()
    out = f"./QC/{plane_name}_qc.png"
    plt.savefig(out, dpi=150, bbox_inches="tight", facecolor="black")
    plt.close()
    print(f"QC image saved to: {out}")

PYEOF
