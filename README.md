# Registration DWIs to Anatomical MRI image

A reproducible and automated pipeline to align diffusion-weighted imaging (DWI) data to anatomical MRI references (e.g., T1-weighted) using configurable transformation stages. The workflow includes b=0 extraction, multi-stage registration (translation, rigid, affine, nonlinear), and full-volume transformation, ensuring spatial alignment suitable for tractography and cross-modal analyses.

---

## Author

**Gabriele Amorosino**
(email: [gabriele.amorosino@utexas.edu](mailto:gabriele.amorosino@utexas.edu))

---

## Description

This pipeline extracts the b=0 volume from a 4D DWI dataset, registers it to a selected anatomical image using ANTs, and applies the computed transformation to the full DWI image using MRtrix3. The workflow is configured via a `config.json` file and supports execution in containerized environments (Singularity), ensuring portability and reproducibility.

---

## Requirements

- [Singularity](https://sylabs.io/guides/latest/user-guide/)

---

## Usage

### Running on Brainlife.io

#### On Brainlife.io via Web UI

1. Navigate to the [Brainlife.io](https://brainlife.io) platform and locate the `app-registration-dwi2anat` app.
2. Click the **Execute** tab.
3. Upload required inputs:
   - 4D DWI NIfTI file (`.nii.gz`)
   - Associated `.bval` and `.bvec` files
   - An anatomical image (e.g., T1w, T2w, or FA)
   - Optionally, a `config.json` to override default parameters
4. Submit the job. Output will include registered DWI images and associated transformation matrices and fields.

#### On Brainlife.io via CLI

1. Install the Brainlife CLI: https://brainlife.io/docs/cli/
2. Log in:
   ```bash
   bl login
   ```
3. Run the app:
   ```bash
   bl app run --id <app_id> --project <project_id> \
     --input dwi:<dwi_id> \
     --input bvals:<bval_id> \
     --input bvecs:<bvec_id> \
     --input t1:<t1_id>
   ```

Replace IDs with the appropriate dataset and project references.

---

### Running Locally

#### Option 1: Using a Configuration File

1. Clone the repository:
   ```bash
   git clone https://github.com/gamorosino/app-registration-dwi2anat.git
   cd app-registration-dwi2anat/main
   ```

2. Create a `config.json`:
   ```json
   {
       "dwi": "sub-01_dwi.nii.gz",
       "bvals": "sub-01.bval",
       "bvecs": "sub-01.bvec",
       "t1": "sub-01_T1w.nii.gz",
       "transformation": "nonlinear",
       "settings": "2"
   }
   ```

3. Run the pipeline:
   ```bash
   bash ./main
   ```

---

## Outputs

- `b0/` — Extracted b=0 volume
- `ANTs_outputs/` — ANTs registration outputs: affine matrix, warp fields
- `transformations/` — Final transformation files (formatted for Brainlife)
- `transformed/` — Fully aligned DWI image



---

## Citation

If you use this repository in your work, please cite the tools and frameworks leveraged:

- Avants et al., *Advanced Normalization Tools (ANTs)*, Insight Journal, 2009.  
- Tournier et al., *MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation*, NeuroImage, 2019. 

---

## License

This project is released under the [MIT License](LICENSE).
