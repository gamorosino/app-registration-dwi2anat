#!/usr/bin/env python3

import numpy as np
import nibabel as nib
import sys
import argparse
from pathlib import Path


def read_bvals(bvals_file):
    with open(bvals_file, 'r') as f:
        content = f.read()
    content = content.replace('\t', ' ')
    content = ' '.join(content.split())
    return np.array([round(float(val)) for val in content.split()])


def find_bvalue(bvals_file, target):
    """Return the index of the first occurrence of the rounded b-value."""
    bvals = read_bvals(bvals_file)
    target = round(float(target))
    indices = np.where(bvals == target)[0]
    return int(indices[0]) if indices.size > 0 else -1


def extract_bvolume(dwi_in, dwi_out, bval, bvals_file):
    idx = find_bvalue(bvals_file, bval)
    if idx == -1:
        print("Cannot find bvalue index", file=sys.stderr)
        return -1

    img = nib.load(dwi_in)
    data = img.get_fdata()
    affine = img.affine

    if data.ndim != 4:
        raise ValueError("Input DWI image must be 4D")

    if idx >= data.shape[3]:
        raise IndexError("Index out of range for DWI volume")

    vol = data[..., idx]
    nib.save(nib.Nifti1Image(vol, affine), dwi_out)
    return 0


def extract_b0(dwi_in, dwi_out, bvals_file):
    bvals = read_bvals(bvals_file)
    idx = find_bvalue(bvals_file, 0)

    if idx == -1:
        bval_min = int(np.min(bvals))
        print(f"b=0 not found, using lowest b-value: {bval_min}")
        idx = find_bvalue(bvals_file, bval_min)

    return extract_bvolume(dwi_in, dwi_out, bvals[idx], bvals_file)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Extract the first b=0 (or lowest b-value) 3D volume from a 4D DWI dataset."
    )
    parser.add_argument("dwi_input", help="Path to the input 4D DWI NIfTI file.")
    parser.add_argument("dwi_output", help="Path to the output 3D volume NIfTI file.")
    parser.add_argument("bvals_file", help="Path to the .bval file corresponding to the DWI.")

    args = parser.parse_args()

    status = extract_b0(args.dwi_input, args.dwi_output, args.bvals_file)
    sys.exit(status)
