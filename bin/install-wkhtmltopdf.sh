#!/bin/bash
set -ex

if [ "${WKHTMLTOPDF_VERSION}" == "0.12.1.2" ]; then
    curl -SLo wkhtmltox.deb "http://nightly.odoo.com/extra/wkhtmltox-${WKHTMLTOPDF_VERSION}_linux-jessie-amd64.deb"
    echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.deb" | sha256sum -c -
    dpkg --force-depends -i wkhtmltox.deb
    apt-get update
    apt-get install -y --no-install-recommends -f
    rm -Rf /var/lib/apt/lists/* wkhtmltox.deb
    wkhtmltopdf --version
    exit 0
fi


{  # wkhtmltox < 0.12.5
    curl -SLo wkhtmltox.tar.xz --fail \
        "https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox-${WKHTMLTOPDF_VERSION}_linux-generic-amd64.tar.xz" \
        && PACKAGE_TYPE=tar
} || {  # wkhtmltox >= 0.12.5
    DEBIAN_CODENAME="$(lsb_release -cs)"
    curl -SLo wkhtmltox.deb --fail \
        "https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}-1.${DEBIAN_CODENAME}_amd64.deb" \
        && PACKAGE_TYPE=deb
}

if [ "${PACKAGE_TYPE}" == "tar" ]; then
    echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.tar.xz" | sha256sum -c -
    tar --strip-components 1 -C /usr/local/ -xf wkhtmltox.tar.xz
    rm wkhtmltox.tar.xz
elif [ "${PACKAGE_TYPE}" == "deb" ]; then
    echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.deb" | sha256sum -c -
    dpkg --install wkhtmltox.deb || true
    apt-get update
    apt-get install -yqq --no-install-recommends --fix-broken
    rm -rf wkhtmltox.deb /var/lib/apt/lists/*
fi

wkhtmltopdf --version
