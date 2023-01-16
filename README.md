# Container image for pdftk-java

[![Build OCI image](https://github.com/pdftk-java/pdftk-java-container/actions/workflows/image.yml/badge.svg)](https://github.com/pdftk-java/pdftk-java-container/actions/workflows/image.yml)
[![Docker pulls](https://img.shields.io/docker/pulls/pdftk/pdftk.svg)](https://hub.docker.com/r/pdftk/pdftk)
[![OCI image size](https://img.shields.io/docker/image-size/pdftk/pdftk/latest.svg)](https://hub.docker.com/r/pdftk/pdftk/tags)

## About

Source files and build instructions for an [OCI](https://opencontainers.org/) image (compatible with e.g. Docker or Podman) for [pdftk-java](https://gitlab.com/pdftk-java/pdftk). If PDF is electronic paper, then pdftk-java is an electronic staple-remover, hole-punch, binder, secret-decoder-ring, and X-Ray-glasses. PDFtk is a simple tool for doing everyday things with PDF documents: Merge PDF documents, split PDF pages into a new document, decrypt input as necessary (password required), encrypt output as desired, burst a PDF document into single pages, report on PDF metrics, including metadata and bookmarks, uncompress and re-compress page streams, and repair corrupted PDF (where possible).
 
Pdftk-java is a port of the original GCJ-based PDFtk to Java. The GNU Compiler for Java (GCJ) is a portable, optimizing, ahead-of-time compiler for the Java programming language, which had no new developments since 2009 and was finally removed in 2016 from the GCC development tree before the release of GCC 7.

## Usage

The OCI image automatically runs pdftk-java with the given options and arguments. It may be started with Docker using:

```shell
docker run --rm --volume $(pwd):/work pdftk/pdftk:latest --help
```

And it may be started with Podman using:

```shell
podman run --rm --volume $(pwd):/work quay.io/pdftk/pdftk:latest --help
```

For command-line convenience it might be suitable to `alias` the command above, e.g.:

```shell
alias pdftk='podman run --rm --volume $(pwd):/work quay.io/pdftk/pdftk:latest'
```

## Volumes

  * `/work` - Default working directory for pdftk-java.

While none of the volumes is required, meaningful usage requires at least persistent storage for `/work`.

## Custom images

For custom OCI images, the following build arguments can be passed:

  * `VERSION` - Version of the pdftk-java release tarball, defaults to `3.3.3`.
  * `GIT` - Git repository URL of pdftk-java, defaults to `https://gitlab.com/pdftk-java/pdftk.git`.
  * `COMMIT` - Git commit, branch or tag of pdftk-java, e.g. `master`, unset by default.

To build a custom OCI image from current Git, e.g. `--build-arg COMMIT=master` needs to be passed.

## Pipeline / Workflow

[Docker Hub](https://hub.docker.com/) and [Quay](https://quay.io/) can both [automatically build](https://docs.docker.com/docker-hub/builds/) OCI images from a [linked GitHub account](https://docs.docker.com/docker-hub/builds/link-source/) and automatically push the built image to the respective container repository. However, as of writing, this leads to OCI images for only the `amd64` CPU architecture. To support as many CPU architectures as possible (currently `386`, `amd64`, `arm/v6`, `arm/v7`, `arm64/v8`, `ppc64le` and `s390x`), [GitHub Actions](https://github.com/features/actions) are used. There, the current standard workflow "[Build and push OCI image](.github/workflows/image.yml)" roughly uses first a [GitHub Action to install QEMU static binaries](https://github.com/docker/setup-qemu-action), then a [GitHub Action to set up Docker Buildx](https://github.com/docker/setup-buildx-action) and finally a [GitHub Action to build and push Docker images with Buildx](https://github.com/docker/build-push-action).

Thus the OCI images are effectively built within the GitHub infrastructure (using [free minutes](https://docs.github.com/en/github/setting-up-and-managing-billing-and-payments-on-github/about-billing-for-github-actions) for public repositories) and then only pushed to both container repositories, Docker Hub and Quay (which are also free for public repositories). This not only saves repeated CPU resources but also ensures identical bugs independent from which container repository the OCI image gets finally pulled (and somehow tries to keep it distant from program changes such as [Docker Hub Rate Limiting](https://www.docker.com/increase-rate-limits) in 2020). The authentication for the pushes to the container repositories happen using access tokens, which at Docker Hub need to be bound to a (community) user and at Quay using a robot account as part of the organization. These access tokens are saved as "repository secrets" as part of the settings of the GitHub project.

To avoid maintaining one `Dockerfile` per CPU architecture, the single one is automatically multi-arched using `sed -e 's/^\(FROM\) \(alpine:.*\)/ARG ARCH=\n\1 ${ARCH}\2/' -i Dockerfile` as part of the workflow itself. While this might feel hackish, it practically works very well.

For each release of the project, a new Git branch (named like the version of the release, e.g. `3.3.3`) is created (based on the default branch, e.g. `master`). The workflow takes care about creating and moving container tags, such as `latest`. By not using Git tags but branches, downstream bug fixes can be easily applied to the OCI image (e.g. for bugs in the `Dockerfile` or patches for the source code itself). Old branches are not touched anymore, equivalent to old release archives.

Each commit to a Git branch triggers the workflow and leads to OCI images being pushed (except for GitHub pull requests), where the container tag is always based on the Git branch name. OCI images with non-release container tags pushed for testing purposes need to be cleaned up manually at the container repositories. Additionally, a cron-like option in the workflow leads to a nightly build being also tagged as `edge`.

[Re-running a workflow](https://docs.github.com/en/actions/managing-workflow-runs/re-running-a-workflow) for failed builds can be performed using the GitHub web interface at the "Actions" section. However, to re-run older or successful builds (e.g. to achieve a newer operating system base image layer for an existing release), `git commit --allow-empty -m "Reason" && git push` might do the trick (because the [GitHub Actions API](https://stackoverflow.com/questions/56435547/how-do-i-re-run-github-actions) doesn't seem to allow such re-runs either).

## License

This project is licensed under the GNU General Public License, version 2 or later - see the [LICENSE](LICENSE) file for details.

As with all OCI images, these also contain other software under other licenses (such as BusyBox, OpenJDK etc. from the base distribution, along with any direct or indirect dependencies of the contained pdftk-java).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
