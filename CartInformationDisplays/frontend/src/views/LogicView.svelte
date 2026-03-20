<script lang="ts">
  import Sponsors from "./Sponsors.svelte";
  import YouTube from "./YouTube.svelte";
  import Twitch from "./Twitch.svelte";
  import Screensaver from "./Screensaver.svelte";

  import createWebsocketTunnel from "../websocketTunnel";
  import { buildMessagePackage } from "../sharedFunctions";

  export let wsEndpoint: string;
  export let presentationId: string;

  const position = (wsEndpoint == "cartL") ? "L" : "R";

  const ws = createWebsocketTunnel("ws://localhost:1701/" + wsEndpoint);

  const views = {
    sponsors: "sponsors",
    youtube: "youtube",
    twitch: "twitch",
    screensaver: "screensaver"
  }

  const player = {
    youtube: "youtube",
    twitch: "twitch"
  } 

  let currentView = views.screensaver;
  let videoID = "";
  let channel = "";

$: if ($ws.message?.type === "state" || ($ws.message?.type === "state" + position)) {
    const key = $ws.message?.data as keyof typeof views;
    currentView = views[key] ?? views.screensaver;
    ws.sendMessage(buildMessagePackage("state", currentView));
}

$: if ($ws.message?.type === "youtubeUpdate") {
    videoID = $ws.message?.data;
    ws.sendMessage(buildMessagePackage("youtubeUpdate", true));

  }

$: if ($ws.message?.type === "twitchUpdate") {
    channel = $ws.message?.data;
    ws.sendMessage(buildMessagePackage("twitchUpdate", true));
  }
</script>

<main>
    {#if currentView === "sponsors"}
      <Sponsors title="Sponsors" url={`https://docs.google.com/presentation/d/e/${presentationId}/embed?start=true&loop=true&delayms=7000&rm=minimal`} />
    {:else if currentView === "youtube"}
        <YouTube {videoID} />
    {:else if currentView === "twitch"}
        <Twitch {channel} />
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