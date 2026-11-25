<h1 align="center">DWI-to-Anatomical MRI Registration</h1>

<p align="center">
  Registers DWI to an anatomical reference (T1w, T2w or FA) with ANTs, using the b0 volume and translation, rigid, affine or SyN stages, applies the transform to the full DWI with MRtrix3 and produces QC figures.
</p>

<p align="center">
  <a href="https://github.com/brainlife/abcd-spec"><img src="https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg" alt="ABCD Spec v1.1"></a>
  <a href="https://doi.org/10.25663/brainlife.app.857"><img src="https://img.shields.io/badge/Brainlife-brainlife.app.857-blue.svg" alt="Run on brainlife.io"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-see_LICENSE-lightgrey.svg" alt="License"></a>
</p>

## At a glance

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

> **Registers DWI to an anatomical reference (T1w, T2w or FA) with ANTs, using the b0 volume and translation, rigid, affine or SyN stages, applies the transform to the full DWI with MRtrix3 and produces QC figures.**

Extracts the first b=0 (or lowest-b) volume, registers it to the chosen anatomical image with antsRegistration up to the selected transformation stage and pyramid depth, then applies the affine and warp to the 4-D DWI (with b-vector handling) and writes before/after QC figures. Provide one fixed image: T1w, T2w or a tensor dataset (FA is used). Optionally checks white-matter overlap on FA before and after registration (qc_wm).

| | |
|---|---|
| **Inputs** | `neuro/dwi` · `neuro/anat/t1w` (optional) · `neuro/anat/t2w` (optional) · `neuro/tensor` (optional) |
| **Outputs** | `neuro/transform/nifti` · `neuro/dwi` · `generic/images` |
| **Container** | `gamorosino/tract_align:v1.1` |
| **Resources** | 1 CPUs · 2 h walltime |
| **Run it** | [doi.org/10.25663/brainlife.app.857](https://doi.org/10.25663/brainlife.app.857) |

#### Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `dwi` | `neuro/dwi` | yes | 4-D diffusion-weighted image with bvals and bvecs (moving image). |
| `t1_fixed` | `neuro/anat/t1w` | no | T1-weighted image used as the fixed reference. |
| `t2_fixed` | `neuro/anat/t2w` | no | T2-weighted image used as the fixed reference if no T1w is given. |
| `tensor_fixed` | `neuro/tensor` | no | Tensor dataset whose FA map is used as the fixed reference if no anatomical image is given. |

#### Outputs

| Output | Datatype | Description |
|---|---|---|
| `transformations` | `neuro/transform/nifti` | ANTs affine matrix and warp fields mapping the DWI to the anatomical reference. |
| `transformed` | `neuro/dwi` | DWI resampled into the anatomical reference space, with bvals and bvecs. |
| `figures` | `generic/images` | Before/after registration QC figures (orthogonal views and slices). |

<details>
<summary><b>Parameters</b> (3)</summary>

| Parameter | Type | Default | Description |
|---|---|---|---|
| `settings` | enum | `4` | The `settings` parameter controls the depth of the multiresolution (pyramidal) registration strategy used by ANTs. Higher settings correspond to more levels in the registration pyramid, starting from coarse alignment and progressively refining toward finer spatial correspondence. Options: `1`, `2`, `3`, `4`. |
| `transformation` | enum | `rigid` | Highest registration stage to run: translation, rigid, affine or nonlinear (SyN); each stage includes the previous ones. Options: `translation`, `rigid`, `affine`, `nonlinear`. |
| `qc_wm` | boolean | `false` | Fits a diffusion tensor model on both the pre- and post-registration DWI, thresholds FA ≥ 0.35 to produce a white matter mask, and overlays it in blue on all QC images so you can verify that the WM geometry aligns with the reference anatomy after registration. |

</details>

<!-- brainlife-app:end -->

## Running the App

### On brainlife.io

Open the App at [doi.org/10.25663/brainlife.app.857](https://doi.org/10.25663/brainlife.app.857), choose `neuro/dwi`, `neuro/anat/t1w`, `neuro/anat/t2w`, `neuro/tensor` from your project, set the parameters and press **Execute**. The results are saved to your project as `neuro/transform/nifti`, `neuro/dwi`, `generic/images`.

### Locally

You need [Singularity/Apptainer](https://apptainer.org/) (the App runs in `gamorosino/tract_align:v1.1`), [`jq`](https://jqlang.github.io/jq/).

1. Clone this repository.
2. Create `config.json` with the paths to your inputs and the parameters:

   ```json
   {
       "dwi": "/path/to/dwi/dwi",
       "bvecs": "/path/to/dwi/bvecs",
       "bvals": "/path/to/dwi/bvals",
       "sbref": "/path/to/dwi/sbref",
       "sbref_json": "/path/to/dwi/sbref_json",
       "t1": "/path/to/t1_fixed/t1",
       "t2": "/path/to/t2_fixed/t2",
       "fa": "/path/to/tensor_fixed/fa",
       "md": "/path/to/tensor_fixed/md",
       "rd": "/path/to/tensor_fixed/rd",
       "ad": "/path/to/tensor_fixed/ad",
       "cl": "/path/to/tensor_fixed/cl",
       "cp": "/path/to/tensor_fixed/cp",
       "cs": "/path/to/tensor_fixed/cs",
       "tensors": "/path/to/tensor_fixed/tensors",
       "kurtosis": "/path/to/tensor_fixed/kurtosis",
       "ga": "/path/to/tensor_fixed/ga",
       "mk": "/path/to/tensor_fixed/mk",
       "ak": "/path/to/tensor_fixed/ak",
       "rk": "/path/to/tensor_fixed/rk",
       "rgb": "/path/to/tensor_fixed/rgb",
       "settings": "4",
       "transformation": "rigid",
       "qc_wm": false
   }
   ```

3. Run `./main`.

## Troubleshooting

- **Invalid transformation type**: Set transformation to translation, rigid, affine or nonlinear.

## Citing

If you use this App, please cite it, the software it builds on and brainlife.io:

- DWI-to-Anatomical MRI Registration. brainlife.io App. [doi:10.25663/brainlife.app.857](https://doi.org/10.25663/brainlife.app.857)
- Avants et al., *Advanced Normalization Tools (ANTs)*, Insight Journal, 2009.
- Tournier et al., *MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation*, NeuroImage, 2019. ---
- Jenkinson et al. FSL. *NeuroImage* 62:782-790 (2012). [doi:10.1016/j.neuroimage.2011.09.015](https://doi.org/10.1016/j.neuroimage.2011.09.015)
- Tournier et al. MRtrix3: A fast, flexible and open software framework for medical image processing and visualisation. *NeuroImage* 202:116137 (2019). [doi:10.1016/j.neuroimage.2019.116137](https://doi.org/10.1016/j.neuroimage.2019.116137)
- Avants et al. A reproducible evaluation of ANTs similarity metric performance in brain image registration. *NeuroImage* 54:2033-2044 (2011). [doi:10.1016/j.neuroimage.2010.09.025](https://doi.org/10.1016/j.neuroimage.2010.09.025)
- Hayashi S, Caron BA, Heinsfeld AS, et al. brainlife.io: a decentralized and open-source cloud platform to support neuroscience research. *Nature Methods* 21:809–813 (2024). [doi:10.1038/s41592-024-02237-2](https://doi.org/10.1038/s41592-024-02237-2)
- Avesani P, McPherson B, Hayashi S, et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. *Scientific Data* 6:69 (2019). [doi:10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

## Authors

**Gabriele Amorosino**
(email:

---

## License

See [LICENSE](LICENSE).
