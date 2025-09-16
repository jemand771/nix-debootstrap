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
        component = [
          "main"
          "contrib"
          "non-free"
          "non-free-firmware"
        ];
        flavor = [
          "binary-amd64"
        ];
      }
      {
        dist = [
          "bullseye"
        ];
        component = [
          "main"
          "contrib"
          "non-free"
        ];
        flavor = [
          "binary-amd64"
        ];
      }
    ];
  };
}
