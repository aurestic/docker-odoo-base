#!/bin/bash

scriptname=$(basename "$(readlink -nf "${0}")")
scriptpath=$(dirname "$(readlink -e -- "${0}")")

odoo=""
rebase=0
github=0

print_help() {
    cat >&2 <<EOF
Usage:
  ${scriptname} --odoo VERSION

Arguments:
  -o, --odoo      version de odoo a hacer build
  -r, --rebase    actualiza el repositorio con upstream
  -g, --github    actualiza la imagen en github
  -h, --help      muestra esta ayuda y finaliza

Examples:
  ${scriptname} --rebase
  ${scriptname} -o 11
  ${scriptname} --odoo 14 --github
  ${scriptname} -o 15 -g

EOF
    exit 1
}

OPTIONS=orgh
LONGOPTS=odoo:,rebase,github,help
PARSED=$(getopt --options=${OPTIONS} --longoptions=${LONGOPTS} \
    --name="${scriptname}" -- "${@}")
if [[ ${?} -ne 0 ]]; then
    echo >&2 "PARSE_ERROR"
    exit 2
fi
eval set -- "${PARSED}"

while :; do
    case "${1}" in
    -o | --odoo)
        odoo="${2}"
        shift 2
        ;;
    -r | --rebase)
        rebase=1
        shift
        ;;
    -g | --github)
        github=1
        shift
        ;;
    -h | --help)
        print_help
        ;;
    --)
        shift
        break
        ;;
    *)
        echo >&2 "PROGRAMMING_ERROR"
        exit 3
        ;;
    esac
done

if [[ ${#} -gt 0 ]]; then
    echo >&2 "Positional arguments found:" "${@}"
    exit 4
fi

if [[ -z "${odoo}" ]] && [[ ${rebase} -eq 0 ]]; then
    echo >&2 "${scriptname}: Missing '-o/--odoo' or -r/--rebase argument."
    exit 1
fi

if [[ "${odoo}" != "" ]]; then
    echo "[INFO] Backup previous image..."
    docker pull dockermaster.aurestic.com/nubeaerp/odoo-base:${odoo}.0-onbuild
    if [[ $? -eq 0 ]]; then
        docker tag \
            dockermaster.aurestic.com/nubeaerp/odoo-base:${odoo}.0-onbuild \
            dockermaster.aurestic.com/nubeaerp/odoo-base:${odoo}.0-onbuild-backup
        echo "[INFO] Backup image: dockermaster.aurestic.com/nubeaerp/odoo-base:${odoo}.0-onbuild-backup"
    else
        echo "[INFO] First time image build..."
    fi
fi

if [[ ${rebase} -eq 1 ]]; then
    echo "[INFO] Updating repository..."
    git branch -D master-upd
    git fetch upstream master:master-upd
    git rebase master-upd
    git push origin master -f
    if [[ $? -eq 0 ]]; then
        echo "[INFO] Repository updated"
    else
        echo "[ERROR] Repository update failed, manual intervention required"
        exit 5
    fi
fi

if [[ "${odoo}" != "" ]]; then
    echo "[INFO] Building ${odoo}.0-onbuild image..."
    docker build \
        -t dockermaster.aurestic.com/nubeaerp/odoo-base:${odoo}.0-onbuild \
        -f ${odoo}.0.Dockerfile .

    if [[ ${github} -eq 1 ]]; then
        echo "[INFO] reTagging image to ghcr.io/aurestic/odoo-base:${odoo}.0-onbuild"
        docker tag \
            dockermaster.aurestic.com/nubeaerp/odoo-base:${odoo}.0-onbuild \
            ghcr.io/aurestic/odoo-base:${odoo}.0-onbuild
    fi
fi

if [[ "${odoo}" != "" ]]; then
    echo "[INFO] Pushing image..."
    docker push dockermaster.aurestic.com/nubeaerp/odoo-base:${odoo}.0-onbuild
    if [[ ${github} -eq 1 ]]; then
        docker push ghcr.io/aurestic/odoo-base:${odoo}.0-onbuild
    fi
fi

echo "[INFO] Process end."
