<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import Hls from 'hls.js';

  export let streamUrl: string;

  let videoEl: HTMLVideoElement;
  let hls: Hls | null = null;

  function initHls(url: string) {
    destroyHls();
    if (!url) return;
    if (Hls.isSupported()) {
      hls = new Hls({
        liveSyncDurationCount: 2,
        liveMaxLatencyDurationCount: 4,
        maxBufferLength: 4,
        enableWorker: true,
      });
      hls.loadSource(url);
      hls.attachMedia(videoEl);
      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        videoEl.play().catch(() => {});
      });
      hls.on(Hls.Events.ERROR, (_event, data) => {
        if (data.fatal) {
          switch (data.type) {
            case Hls.ErrorTypes.NETWORK_ERROR:
              hls?.startLoad();
              break;
            case Hls.ErrorTypes.MEDIA_ERROR:
              hls?.recoverMediaError();
              break;
            default:
              destroyHls();
              setTimeout(() => initHls(url), 3000);
          }
        }
      });
    } else if (videoEl.canPlayType('application/vnd.apple.mpegurl')) {
      videoEl.src = url;
      videoEl.play().catch(() => {});
    }
  }

  function destroyHls() {
    hls?.destroy();
    hls = null;
  }

  onMount(() => initHls(streamUrl));

  $: if (videoEl && streamUrl) initHls(streamUrl);

  onDestroy(() => destroyHls());
</script>

<video
  bind:this={videoEl}
  autoplay
  muted
  playsinline
></video>

<style>
  video {
    width: 100%;
    height: 100%;
    object-fit: contain;
    background: black;
  }
</style>
