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
  atk,
  fontconfig,
  freetype,
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
  libXcursor,
  libXi,
  libXrender,
  libXtst,
  libxshmfence,
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
    atk
    fontconfig
    freetype

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
    libXcursor
    libXi
    libXrender
    libXtst
    libxshmfence

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

    # 1. Install the entire opt tree
    mkdir -p $out
    cp -r opt $out/

    # 2. Create symlinks for binaries in $out/bin
    # We link to the one in opt so it can find its resources/app.asar relative to itself
    mkdir -p $out/bin
    ln -s $out/opt/docker-desktop/bin/docker-desktop $out/bin/docker-desktop
    install -Dm755 usr/bin/docker-credential-desktop $out/bin/docker-credential-desktop

    # 3. Install CLI plugins
    mkdir -p $out/lib/docker/cli-plugins
    if [ -d usr/lib/docker/cli-plugins ]; then
      cp usr/lib/docker/cli-plugins/* $out/lib/docker/cli-plugins/
    fi

    # 4. Systemd Service - Point to the wrapped bin in $out/bin
    install -Dm644 usr/lib/systemd/user/docker-desktop.service $out/lib/systemd/user/docker-desktop.service
    substituteInPlace $out/lib/systemd/user/docker-desktop.service \
      --replace "/opt/docker-desktop/bin/docker-desktop" "$out/bin/docker-desktop" \
      --replace "/opt/docker-desktop" "$out/opt/docker-desktop"

    # 5. Desktop File - Point Exec to the wrapped bin and fix Icon
    if [ -f usr/share/applications/docker-desktop.desktop ]; then
      install -Dm644 usr/share/applications/docker-desktop.desktop $out/share/applications/docker-desktop.desktop
      substituteInPlace $out/share/applications/docker-desktop.desktop \
        --replace-fail "/opt/docker-desktop/bin/docker-desktop" "$out/bin/docker-desktop" \
        --replace-fail "/opt/docker-desktop" "$out/opt/docker-desktop" \
        --replace-fail "Icon=$out/opt/docker-desktop/share/icon.original.png" "Icon=docker-desktop"
    fi

    # 6. Icon
    if [ -f opt/docker-desktop/share/icon.original.png ]; then
      install -Dm644 opt/docker-desktop/share/icon.original.png \
        $out/share/icons/hicolor/256x256/apps/docker-desktop.png
    fi

    runHook postInstall
  '';

  postInstall = ''
    # Wrap the binary inside opt so the symlink in $out/bin uses these environment settings
    wrapProgram $out/opt/docker-desktop/bin/docker-desktop \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath (finalAttrs.buildInputs ++ [ stdenv.cc.cc.lib ])
      }" \
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
      --set DOCKER_CONFIG "\$HOME/.docker"
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
