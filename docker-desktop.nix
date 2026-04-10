{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  lib,
  # Electron/GUI dependencies
  gtk3,
  glib,
  cairo,
  pango,
  gdk-pixbuf,
  at-spi2-atk,
  at-spi2-core,
  # X11 dependencies
  libxkbcommon,
  libdrm,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  mesa,
  # Audio
  alsa-lib,
  libpulseaudio,
  # System libraries
  dbus,
  nspr,
  nss,
  cups,
  libglvnd,
  libgbm,
  expat,
  libuuid,
  systemd,
  # Docker integration
  docker,
  qemu,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "docker-desktop";
  version = "4.62.0";

  tag = "219486";

  src = fetchurl {
    url = "https://desktop.docker.com/linux/main/amd64/${finalAttrs.tag}/docker-desktop-amd64.deb";
    hash = "sha256-UmmA+ideOINMyAYHut18jVamBoZwr0msx5I//44mAZ4=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib

    # GTK/GUI stack (for Electron)
    gtk3
    glib
    cairo
    pango
    gdk-pixbuf
    at-spi2-atk
    at-spi2-core

    # X11
    libxkbcommon
    libdrm
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb

    # Graphics
    mesa

    # Audio
    alsa-lib
    libpulseaudio

    # System
    dbus
    nspr
    nss
    cups
    libglvnd
    libgbm
    expat
    libuuid
    systemd
  ];

  # Tell autoPatchelf where to look for shared libraries
  patchelfFlags = [ "--force-rpath" ];

  sourceRoot = ".";
  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  configurePhase = "true";
  buildPhase = "true";

  installPhase = ''
    runHook preInstall

    # Create directory structure
    install -d \
      $out/bin \
      $out/lib/docker/cli-plugins \
      $out/lib/systemd/user \
      $out/share/applications \
      $out/share/licenses/${finalAttrs.pname} \
      $out/share/icons/hicolor/256x256/apps

    # Install main binary (wrapper script from opt/docker-desktop/bin/)
    install -Dm755 opt/docker-desktop/bin/docker-desktop \
      $out/bin/docker-desktop

    # Install the actual Electron app
    cp -r opt/docker-desktop \
      $out/opt/

    # Install credential helper
    install -Dm755 usr/bin/docker-credential-desktop \
      $out/bin/docker-credential-desktop

    # Install systemd service
    install -Dm644 usr/lib/systemd/user/docker-desktop.service \
      $out/lib/systemd/user/docker-desktop.service
    substituteInPlace $out/lib/systemd/user/docker-desktop.service \
      --replace "/opt/docker-desktop" "$out/opt/docker-desktop"

    # Install CLI plugins
    for plugin in \
      docker-buildx \
      docker-compose \
      docker-extension \
      docker-init \
      docker-mcp \
      docker-scout; do
      if [ -f "usr/lib/docker/cli-plugins/$plugin" ]; then
        install -Dm755 "usr/lib/docker/cli-plugins/$plugin" \
          "$out/lib/docker/cli-plugins/$plugin"
      fi
    done

    # Install desktop file and fix paths
    if [ -f usr/share/applications/docker-desktop.desktop ]; then
      install -Dm644 usr/share/applications/docker-desktop.desktop \
        $out/share/applications/docker-desktop.desktop
      substituteInPlace $out/share/applications/docker-desktop.desktop \
        --replace-fail "/opt/docker-desktop" "$out/opt/docker-desktop"
      # Use standard icon name instead of full path
      substituteInPlace $out/share/applications/docker-desktop.desktop \
        --replace-fail "Icon=$out/opt/docker-desktop/share/icon.original.png" "Icon=docker-desktop"
    fi

    # Install icon with standard name
    if [ -f usr/share/icons/hicolor/256x256/apps/icon.original.png ]; then
      install -Dm644 usr/share/icons/hicolor/256x256/apps/icon.original.png \
        $out/share/icons/hicolor/256x256/apps/docker-desktop.png
    fi

    runHook postInstall
  '';

  # Wrapper script to set up the environment
  postInstall = ''
    # Wrap the main binary with proper library path
    wrapProgram $out/bin/docker-desktop \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --prefix PATH : "${
        lib.makeBinPath [
          docker
          qemu
        ]
      }" \
      --add-flags "--disable-gpu-sandbox" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations" \
      --set DOCKER_DESKTOP_CLI_VERSION "${finalAttrs.version}" \
      --set DOCKER_CONFIG "$HOME/.docker"
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
