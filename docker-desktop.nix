{
  stdenv,
  fetchurl,
  curl,
  desktop-file-utils,
  docker,
  dpkg,
  gtk3,
  libcap_ng,
  libseccomp,
  lib,
  pass,
  qemu,
  shadow,
  libx11,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "docker-desktop";
  version = "4.62.0";

  tag = "219486";

  src = fetchurl {
    url = "https://desktop.docker.com/linux/main/amd64/${finalAttrs.tag}/docker-desktop-amd64.deb";
    hash = "sha256-UmmA+ideOINMyAYHut18jVamBoZwr0msx5I//44mAZ4=";
  };

  # licenseSrc = fetchurl {
  #   url = "https://www.docker.com/legal/docker-subscription-service-agreement/";
  #   hash = "sha256-0jsr5zawh0ygpjnc4c2ak4yjv6mg05nljcf2d54c8whmha63knn2";
  # };

  nativeBuildInputs = [ dpkg ];

  propagatedBuildInputs = [
    curl
    desktop-file-utils
    docker
    gtk3
    libcap_ng
    libseccomp
    pass
    qemu
    shadow
    libx11
  ];

  sourceRoot = ".";
  unpackPhase = ''
    dpkg -x $src .
  '';

  installPhase = ''
    runHook preInstall
    install -d \
      $out/bin \
      $out/lib/docker/cli-plugins \
      $out/lib/systemd/user \
      $out/opt \
      $out/share/applications \
      $out/share/licenses/${finalAttrs.pname}

    install -Dm755 usr/bin/docker-credential-desktop \
      $out/bin/docker-credential-desktop

    install -Dm644 usr/lib/systemd/user/docker-desktop.service \
      $out/lib/systemd/user/docker-desktop.service

    # for plugin in \
    #   docker-ai \
    #   docker-buildx \
    #   docker-compose \
    #   docker-debug \
    #   docker-desktop \
    #   docker-extension \
    #   docker-init \
    #   docker-mcp \
    #   docker-offload \
    #   docker-pass \
    #   docker-sbom \
    #   docker-scout; do
    #   install -Dm755 usr/lib/docker/cli-plugins/$plugin \
    #     $out/lib/docker/cli-plugins/$plugin
    # done

    cp -r opt/* $out/opt/
    install -Dm644 usr/share/applications/* $out/share/applications/
    # install -Dm644 $licenseSrc \
    #   $out/share/licenses/${finalAttrs.pname}/docker-agreement.txt

    runHook postInstall
  '';

  meta = {
    description = "Docker Desktop for Linux";
    homepage = "https://docs.docker.com/desktop";
    downloadPage = "https://docs.docker.com/desktop/release-notes";
    mainProgram = "docker-desktop";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    maintainers = with lib.maintainers; [ MH0386 ];
  };
})
