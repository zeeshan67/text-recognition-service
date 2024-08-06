## Builds binaries for Amazonlinux 2
FROM public.ecr.aws/sam/build-provided.al2:1.97

ARG LEPTONICA_VERSION=1.84.1
ARG TESSERACT_VERSION=5.4.1
ARG AUTOCONF_ARCHIVE_VERSION=2017.09.28
ARG TMP_BUILD=/tmp
ARG TESSERACT=/opt/tesseract
ARG LEPTONICA=/opt/leptonica
ARG DIST=/opt/build-dist
ARG OCR_LANG=deu
ARG TESSERACT_DATA_SUFFIX=_fast
ARG TESSERACT_DATA_VERSION=4.1.0

# Install essential development tools and libraries
RUN yum makecache fast && \
    yum clean all && yum -y update && yum -y upgrade && \
    yum clean all && yum -y install yum-plugin-ovl && \
    yum clean all && yum -y groupinstall "Development Tools" && \
    yum clean all && yum -y install \
    gcc gcc-c++ make autoconf automake libtool \
    libjpeg-devel libpng-devel libtiff-devel zlib-devel \
    libzip-devel freetype-devel lcms2-devel libwebp-devel \
    libicu-devel tcl-devel tk-devel pango-devel cairo-devel \
    libgomp && yum clean all

# Create directories for building
WORKDIR ${TMP_BUILD}/leptonica-build
RUN curl -L https://github.com/DanBloomberg/leptonica/releases/download/${LEPTONICA_VERSION}/leptonica-${LEPTONICA_VERSION}.tar.gz | tar xz && \
    cd ${TMP_BUILD}/leptonica-build/leptonica-${LEPTONICA_VERSION} && \
    ./configure --prefix=${LEPTONICA} && make && make install && cp -r ./src/.libs /opt/liblept

# Set PKG_CONFIG_PATH for Leptonica
ENV PKG_CONFIG_PATH=${LEPTONICA}/lib/pkgconfig:$PKG_CONFIG_PATH

# Configure library paths
RUN echo "/opt/leptonica/lib" > /etc/ld.so.conf.d/leptonica.conf && /usr/sbin/ldconfig

# Build and install autoconf-archive
WORKDIR ${TMP_BUILD}/autoconf-build
RUN curl -L https://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-${AUTOCONF_ARCHIVE_VERSION}.tar.xz | tar xJ && \
    cd autoconf-archive-${AUTOCONF_ARCHIVE_VERSION} && ./configure && make && make install && cp ./m4/* /usr/share/aclocal/

# Build and install Tesseract
WORKDIR ${TMP_BUILD}/tesseract-build
RUN curl -L https://github.com/tesseract-ocr/tesseract/archive/refs/tags/${TESSERACT_VERSION}.tar.gz | tar xz && \
    cd tesseract-${TESSERACT_VERSION} && ./autogen.sh && \
    ./configure --prefix=${TESSERACT} --with-extra-includes=/opt/leptonica/include --with-extra-libraries=/opt/leptonica/lib && \
    make && make install

# Prepare the output
WORKDIR /opt
RUN mkdir -p ${DIST}/lib && mkdir -p ${DIST}/bin && \
    cp ${TESSERACT}/bin/tesseract ${DIST}/bin/ && \
    cp ${TESSERACT}/lib/libtesseract.so.5  ${DIST}/lib/ && \
    cp ${LEPTONICA}/lib/libleptonica.so.6.0.0 ${DIST}/lib/libleptonica.so.6 && \
    cp /usr/lib64/libgomp.so.1 ${DIST}/lib/ && \
    cp /usr/lib64/libwebp.so.4 ${DIST}/lib/ && \
    cp /usr/lib64/libpng15.so.15 ${DIST}/lib/ && \
    cp /usr/lib64/libjpeg.so.62 ${DIST}/lib/ && \
    cp /usr/lib64/libtiff.so.5 ${DIST}/lib/ && \
    cp /usr/lib64/libjbig.so.2.0 ${DIST}/lib/ && \
    echo -e "LEPTONICA_VERSION=${LEPTONICA_VERSION}\nTESSERACT_VERSION=${TESSERACT_VERSION}\nTESSERACT_DATA_FILES=tessdata${TESSERACT_DATA_SUFFIX}/${TESSERACT_DATA_VERSION}\nTESSERACT_DATA_LANGUAGES=osd,eng,${OCR_LANG}" > ${DIST}/TESSERACT-README.md && \
    find ${DIST}/lib -name '*.so*' | xargs strip -s

# Download language data files
WORKDIR ${DIST}/tesseract/share/tessdata
RUN curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/osd.traineddata > osd.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/eng.traineddata > eng.traineddata && \
    curl -L https://github.com/tesseract-ocr/tessdata${TESSERACT_DATA_SUFFIX}/raw/${TESSERACT_DATA_VERSION}/${OCR_LANG}.traineddata > ${OCR_LANG}.traineddata

WORKDIR /var/task
