#
# Copyright (C) 2021-2022  Robert Scheck <robert@fedoraproject.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

FROM alpine:latest

LABEL maintainer="Robert Scheck <https://github.com/pdftk-java/pdftk-java-container>" \
      description="GCJ-free toolkit for manipulating PDF documents" \
      org.opencontainers.image.title="pdftk-java" \
      org.opencontainers.image.description="GCJ-free toolkit for manipulating PDF documents" \
      org.opencontainers.image.url="https://gitlab.com/pdftk-java/pdftk" \
      org.opencontainers.image.documentation="https://gitlab.com/pdftk-java/pdftk/-/blob/master/README.md" \
      org.opencontainers.image.source="https://gitlab.com/pdftk-java/pdftk" \
      org.opencontainers.image.licenses="GPL-2.0+" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.name="pdftk-java" \
      org.label-schema.description="GCJ-free toolkit for manipulating PDF documents" \
      org.label-schema.url="https://gitlab.com/pdftk-java/pdftk" \
      org.label-schema.usage="https://gitlab.com/pdftk-java/pdftk/-/blob/master/README.md" \
      org.label-schema.vcs-url="https://gitlab.com/pdftk-java/pdftk"

ARG VERSION=3.3.2
ARG GIT
ARG COMMIT
ARG BOUNCYCASTLE=r1rv71
ARG COMMONSLANG3=3.12.0

RUN set -x && \
  export BUILDREQ="git apache-ant maven" && \
  apk --no-cache upgrade && \
  apk --no-cache add ${BUILDREQ} openjdk8-jre-base && \
  cd /tmp && \
  wget https://github.com/bcgit/bc-java/archive/${BOUNCYCASTLE}.tar.gz -O bc-java-${BOUNCYCASTLE}.tar.gz && \
  tar xfz bc-java-${BOUNCYCASTLE}.tar.gz && \
  cd bc-java-${BOUNCYCASTLE} && \
  sed -e '/javadoc-/d' -i ant/jdk15+.xml && \
  ant -f ant/jdk15+.xml -Dbc.javac.source=1.8 -Dbc.javac.target=1.8 clean build-provider build && \
  install -D -p -m 0644 build/artifacts/jdk1.5/jars/bcprov-ext-jdk15to18-*.jar /usr/share/java/bcprov.jar && \
  cd .. && \
  rm -rf bc-java-${BOUNCYCASTLE}* && \
  jsf=/usr/lib/jvm/java-1.8-openjdk/jre/lib/security/java.security OIFS=$IFS IFS=$'\n' && \
  cp -pf ${jsf} ${jsf}.bc && \
  sed -e 's/^security\.provider\.1=.*/security.provider.next/' -e '/^security\.provider\.[0-9].*/d' -i ${jsf}.bc && \
  for sp in $(grep '^security\.provider\.' ${jsf}); do \
    sed -e "s|^\(security\.provider\.next\)|security.provider.${i:-1}=${sp/*=/}\n\1|" -i ${jsf}.bc && \
    i=$((${i:-1} + 1)); \
  done && \
  IFS=$OIFS && \
  sed -e "s|^\(security\.provider\.next\)|security.provider.${i}=org.bouncycastle.jce.provider.BouncyCastleProvider|" -i ${jsf}.bc && \
  ! diff -u ${jsf} ${jsf}.bc && \
  mv -f ${jsf}.bc ${jsf} && \
  wget https://archive.apache.org/dist/commons/lang/source/commons-lang3-${COMMONSLANG3}-src.tar.gz && \
  tar xfz commons-lang3-${COMMONSLANG3}-src.tar.gz && \
  cd commons-lang3-${COMMONSLANG3}-src* && \
  mvn package -DskipTests -Dmaven.javadoc.skip=true -Dmaven.repo.local=/tmp/commons-lang3-${COMMONSLANG3}-m2 && \
  install -D -p -m 0644 target/commons-lang3-${COMMONSLANG3}.jar /usr/share/java/commons-lang3.jar && \
  cd .. && \
  rm -rf commons-lang3-${COMMONSLANG3}* /usr/share/java/maven* && \
  if [ -z "${GIT}" -a -z "${COMMIT}" ]; then \
    wget https://gitlab.com/pdftk-java/pdftk/-/archive/v${VERSION}/pdftk-v${VERSION}.tar.gz && \
    tar xfz pdftk-v${VERSION}.tar.gz && \
    cd pdftk-v${VERSION}; \
  else \
    git clone ${GIT:-https://gitlab.com/pdftk-java/pdftk.git} && \
    cd pdftk && \
    git checkout ${COMMIT:-master}; \
  fi && \
  mkdir lib/ && \
  cp -pf /usr/share/java/bcprov.jar /usr/share/java/commons-lang3.jar lib/ && \
  ant -Dant.build.javac.source=1.8 -Dant.build.javac.target=1.8 jar && \
  install -D -p -m 0644 build/jar/pdftk.jar /usr/share/java/pdftk.jar && \
  echo -e '#!/bin/sh\nexec /usr/bin/java -classpath /usr/share/java/bcprov.jar:/usr/share/java/commons-lang3.jar:/usr/share/java/pdftk.jar com.gitlab.pdftk_java.pdftk "${@}"' > /usr/bin/pdftk && \
  chmod 0755 /usr/bin/pdftk && \
  set -euo pipefail && \
  pdftk test/files/duck.pdf test/files/duck.pdf output two-ducks.pdf && \
  pdftk two-ducks.pdf dump_data | grep -q "NumberOfPages: 2" && \
  pdftk test/files/duck.pdf rotate 1east output rotated-duck.pdf && \
  pdftk rotated-duck.pdf dump_data | grep -q "PageMediaRotation: 90" && \
  cd .. && \
  rm -rf pdftk* && \
  apk --no-cache del ${BUILDREQ} && \
  mkdir /work && \
  pdftk --version

VOLUME ["/work"]
WORKDIR /work

ENTRYPOINT ["/usr/bin/pdftk"]
CMD ["--help"]
