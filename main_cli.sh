#! /bin/bash

#########################################################################################################################
#########################################################################################################################
###################                                                                                   ###################
###################     title:             Local launcher — build config.json and run main            ###################
###################                                                                                   ###################
###################     usage:             main_cli.sh --dwi <path> --bvecs <path> --bvals <path>     ###################
###################                        --t1w <path> [--t2w <path>] [--parc <path>]               ###################
###################                        [--mask <path>] [--fa <path>]                             ###################
###################                        [--lmax <int>] [--transformation <type>]                  ###################
###################                        [--settings <1-4>]                                         ###################
###################                                                                                   ###################
###################     transformation:    translation | rigid | affine | nonlinear  (def: nonlinear) ###################
###################     settings:          1 | 2 | 3 | 4                             (def: 3)         ###################
###################     lmax:              even integer                               (def: 8)         ###################
###################                                                                                   ###################
###################     autor: gamorosino                                                             ###################
#########################################################################################################################
#########################################################################################################################

SCRIPT=$(realpath -s "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")

usage() {
    echo "Usage: $(basename $0) --dwi <path> --bvecs <path> --bvals <path>"
    echo "                       ( --t1w <path> | --t2w <path> | --fa <path> )"
    echo "                       [--parc <path>] [--mask <path>]"
    echo "                       [--lmax <int>] [--transformation translation|rigid|affine|nonlinear]"
    echo "                       [--settings 1|2|3|4]"
    exit 1
}

# ── defaults ──────────────────────────────────────────────────────────────────
dwi=""
bvecs=""
bvals=""
t1w="null"
t2w="null"
parc="null"
mask="null"
fa="null"
lmax=8
transformation="nonlinear"
settings=3
qc_wm=false

# ── parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dwi)           dwi=$(realpath "$2");           shift 2 ;;
        --bvecs)         bvecs=$(realpath "$2");         shift 2 ;;
        --bvals)         bvals=$(realpath "$2");         shift 2 ;;
        --t1w)           t1w=$(realpath "$2");           shift 2 ;;
        --t2w)           t2w=$(realpath "$2");           shift 2 ;;
        --parc)          parc=$(realpath "$2");          shift 2 ;;
        --mask)          mask=$(realpath "$2");          shift 2 ;;
        --fa)            fa=$(realpath "$2");            shift 2 ;;
        --lmax)          lmax=$2;                        shift 2 ;;
        --transformation) transformation=$2;             shift 2 ;;
        --settings)      settings=$2;                    shift 2 ;;
        --qc_wm)         qc_wm=true;                    shift 1 ;;
        -h|--help)       usage ;;
        *) echo "Unknown argument: $1"; usage ;;
    esac
done

# ── validate required fields ──────────────────────────────────────────────────
errors=0

for var_name in dwi bvecs bvals; do
    val="${!var_name}"
    if [ -z "$val" ]; then
        echo "Error: --${var_name} is required" >&2
        errors=1
    elif [ ! -f "$val" ]; then
        echo "Error: --${var_name} file not found: $val" >&2
        errors=1
    fi
done

if [ "$t1w" = "null" ] && [ "$t2w" = "null" ] && [ "$fa" = "null" ]; then
    echo "Error: at least one anatomical reference is required (--t1w, --t2w, or --fa)" >&2
    errors=1
fi

case "$transformation" in
    translation|rigid|affine|nonlinear) ;;
    *) echo "Error: --transformation must be one of: translation rigid affine nonlinear" >&2; errors=1 ;;
esac

case "$settings" in
    1|2|3|4) ;;
    *) echo "Error: --settings must be one of: 1 2 3 4" >&2; errors=1 ;;
esac

[ $errors -ne 0 ] && exit 1

# ── helper: quote a path or emit JSON null ─────────────────────────────────────
json_val() {
    local v="$1"
    if [ "$v" = "null" ]; then
        echo "null"
    else
        # jq --arg handles escaping
        jq -n --arg v "$v" '$v'
    fi
}

# ── write config.json ─────────────────────────────────────────────────────────
cat > config.json <<EOF
{
  "dwi":            $(json_val "$dwi"),
  "bvecs":          $(json_val "$bvecs"),
  "bvals":          $(json_val "$bvals"),
  "t1":             $(json_val "$t1w"),
  "t2":             $(json_val "$t2w"),
  "parc":           $(json_val "$parc"),
  "mask":           $(json_val "$mask"),
  "fa":             $(json_val "$fa"),
  "lmax":           $lmax,
  "transformation": "$(echo $transformation)",
  "settings":       "$(echo $settings)",
  "qc_wm":          $qc_wm
}
EOF

echo "config.json written:"
cat config.json

# ── run main ──────────────────────────────────────────────────────────────────
echo ""
echo "Running: bash ${SCRIPT_DIR}/main"
bash "${SCRIPT_DIR}/main"
