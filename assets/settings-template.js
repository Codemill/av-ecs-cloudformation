export default {
  backendUrl: "/api",
  licenseKey:
    "<licencense-key>",
  showThemeSelect: false,
  showAssetView: true,
  timeline: {
    waveforms: {
      active: "analyze",
      analyze: {
        url: "/api/analyze/",
      }
    }
  },
  audioQc: {
    preferredAudioShapes: ["aac-discrete-audio", "pcm-discrete-audio", "mp3-discrete-audio"],
    preferredVideoShapes: ["h264", "h264-timecode", "h265", "original", "AV1"]
  },
  ingest: {
    preferredVideoShapes: [
      "mp4-6track",
      "mp4",
      "original",
      "mp4-lowres",
      "lowres",
      "h264",
      "h265",
      "h264-timecode",
      "AV1"
    ],
    preferredAudioShapes: [
      "mp4-6track",
      "mp4-8track",
      "acc-discrete-audio",
      "mp3-discrete-audio",
      "pcm-discrete-audio"
    ],
    preferredSubtitleShapes: ["original"]
  }
};
