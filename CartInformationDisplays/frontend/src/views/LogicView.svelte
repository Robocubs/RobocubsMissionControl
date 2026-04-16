<script lang="ts">
  import Sponsors from "./Sponsors.svelte";
  import YouTube from "./YouTube.svelte";
  import Twitch from "./Twitch.svelte";
  import Livestream from "./Livestream.svelte";
  import Screensaver from "./Screensaver.svelte";

  import createWebsocketTunnel from "../websocketTunnel";

  export let wsEndpoint: string;
  export let presentationId: string;

  const position = (wsEndpoint == "cartL") ? "L" : "R";

  const ws = createWebsocketTunnel("ws://localhost:1701/" + wsEndpoint);

  const views = {
    sponsors: "sponsors",
    youtube: "youtube",
    twitch: "twitch",
    livestream: "livestream",
    screensaver: "screensaver"
  }

  const player = {
    youtube: "youtube",
    twitch: "twitch"
  } 

  let currentView = views.screensaver;
  let streamType = player.youtube;
  let videoID = "";
  let channel = "";
  let livestreamUrl = "";

$: if ($ws.message?.type === "state" || ($ws.message?.type === "state" + position)) {
    const key = $ws.message?.data as keyof typeof views;
    currentView = views[key] ?? views.sponsors;
}

$: if ($ws.message?.type === "youtubeUpdate") {
    videoID = $ws.message?.data;
  }

$: if ($ws.message?.type === "twitchUpdate") {
    channel = $ws.message?.data;
  }

$: if ($ws.message?.type === "livestreamUpdate") {
    livestreamUrl = $ws.message?.data
      ? `http://localhost:1701/hls_${position}/stream.m3u8`
      : "";
  }
</script>

<main>
    {#if currentView === "sponsors"}
      <Sponsors title="Sponsors" url={`https://docs.google.com/presentation/d/e/${presentationId}/embed?start=true&loop=true&delayms=7000&rm=minimal`} />
    {:else if currentView === "youtube"}
        <YouTube {videoID} />
    {:else if currentView === "twitch"}
        <Twitch {channel} />
    {:else if currentView === "livestream"}
        <Livestream streamUrl={livestreamUrl} />
    {:else if currentView === "screensaver"}
      <Screensaver position={position} />
  {/if}
</main>

<style>
  main {
    height: 100vh;
    width: 100vw;
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;
  }
</style>