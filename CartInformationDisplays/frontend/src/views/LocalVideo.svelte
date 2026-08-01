<script lang="ts">
  // media: {id, url, name, duration} pushed by the server, or null if
  // nothing has been selected for this cart yet (or the selection expired).
  export let media: { id: string; url: string; name?: string; duration?: number } | null;
  // The websocket tunnel from LogicView, passed down so this component can
  // both read commands ($ws.message) and write status reports (ws.sendMessage).
  // Left untyped, matching how LogicView itself uses the (untyped JS)
  // createWebsocketTunnel return value — over-typing this as a store
  // interface breaks Svelte's $ws auto-subscription inference.
  export let ws: any;

  type ResumeState = { position?: number; paused?: boolean; muted?: boolean; loop?: boolean };

  let el: HTMLVideoElement;
  let lastSentAt = 0;
  const REPORT_INTERVAL_MS = 500; // timeupdate fires ~4Hz; no need to report that often

  function report(force = false) {
    if (!el || !media) return;
    const now = performance.now();
    if (!force && now - lastSentAt < REPORT_INTERVAL_MS) return;
    lastSentAt = now;
    ws.sendMessage(JSON.stringify({
      type: "localVideoStatus",
      data: {
        id: media.id,
        position: el.currentTime,
        duration: el.duration || media.duration || 0,
        paused: el.paused,
        muted: el.muted,
        loop: el.loop,
        ended: el.ended,
        ready: el.readyState >= 2,
      },
    }));
  }

  function applyCommand(command: { action: string; seconds?: number; flag?: boolean }) {
    if (!el || !command) return;
    switch (command.action) {
      case "play":
        el.play();
        break;
      case "pause":
        el.pause();
        break;
      case "restart":
        el.currentTime = 0;
        el.play();
        break;
      case "seek":
        if (typeof command.seconds === "number") el.currentTime = command.seconds;
        break;
      case "mute":
        if (typeof command.flag === "boolean") el.muted = command.flag;
        break;
      case "loop":
        if (typeof command.flag === "boolean") el.loop = command.flag;
        break;
    }
    report(true);
  }

  function applyResume(resume: ResumeState | null) {
    if (!el || !resume) return;
    if (typeof resume.muted === "boolean") el.muted = resume.muted;
    if (typeof resume.loop === "boolean") el.loop = resume.loop;
    // currentTime is only meaningful once metadata has loaded; onReady
    // re-applies position for that reason.
    if (typeof resume.position === "number") el.currentTime = resume.position;
    if (resume.paused === false) el.play();
    else if (resume.paused === true) el.pause();
  }

  let lastResume: ResumeState | null = null;
  let pendingResume: ResumeState | null = null;

  function onReady() {
    if (pendingResume) {
      applyResume(pendingResume);
      pendingResume = null;
    }
  }

  $: if ($ws.message?.type === "localVideoCommand") {
    applyCommand($ws.message.data);
  }

  $: if ($ws.message?.type === "localVideoResume") {
    lastResume = $ws.message.data;
    if (el && el.readyState >= 1) {
      applyResume(lastResume);
    } else {
      pendingResume = lastResume;
    }
  }
</script>

<div class="wrap">
  {#if media}
    <!-- svelte-ignore a11y-media-has-caption -->
    <video
      bind:this={el}
      src={media.url}
      autoplay
      muted
      playsinline
      preload="auto"
      disablepictureinpicture
      on:loadedmetadata={onReady}
      on:timeupdate={() => report()}
      on:play={() => report(true)}
      on:pause={() => report(true)}
      on:seeked={() => report(true)}
      on:ended={() => report(true)}
    ></video>
  {:else}
    <div class="empty">No video selected</div>
  {/if}
</div>

<style>
  .wrap {
    height: 100vh;
    width: 100vw;
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    background: black;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  video {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }
  .empty {
    color: #444;
    font-family: sans-serif;
    font-size: 2rem;
  }
</style>
