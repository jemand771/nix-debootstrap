let
  component = [
    "main"
    "contrib"
    "non-free"
    "non-free-firmware"
  ];
  componentOld = [
    "main"
    "contrib"
    "non-free"
  ];
  flavor = [
    "binary-amd64"
    "binary-arm64"
    "binary-armhf"
  ];
in
{
  debian = {
    baseUrl = "https://snapshot.debian.org/archive/debian/20250817T082947Z/";
    distReleaseHashes = {
      trixie = "sha256-SPJcH1gsULfUPTdIHZmcLlM3WW2UifKuMxROFK/kodk=";
      bookworm = "sha256-ydFHWAjQD8Hlf2MrsXlg+ntu0NrvOICXb2hgeuvYk7Y=";
      bullseye = "sha256-2y1Pv0P816CBJOf7w4fS6OJZnwGFiqfib26daKWDVlc=";
      bullseye-updates = "sha256-+UZ+OuuoYKaYkjxVXNt7qSLj8HTwTvny485SJgnDbKQ=";
    };
    cartesianMaps = [
      {
        dist = [
          "bookworm"
          "trixie"
        ];
        inherit component flavor;
      }
      {
        dist = [
          "bullseye"
          "bullseye-updates"
        ];
        component = componentOld;
        inherit flavor;
      }
    ];
  };
  debian-archive = {
    baseUrl = "https://archive.debian.org/debian/";
    distReleaseHashes = {
      bullseye-backports = "sha256-x0tlQ4j0tU5SaBIqEU9L68qx8pbLnvjY3wKsxrJoF0Q=";
    };
    cartesianMaps = [
      {
        dist = [
          "bullseye-backports"
        ];
        component = componentOld;
        inherit flavor;
      }
    ];
  };
}
