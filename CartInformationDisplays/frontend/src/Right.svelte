<script lang="ts">
  import Sponsors from "./views/Sponsors.svelte";
  import YouTube from "./views/YouTube.svelte";
  import Twitch from "./views/Twitch.svelte";

  import createWebsocketTunnel from "./websocketTunnel";

  const ws = createWebsocketTunnel("ws://localhost:8010/cartL");

  let currentView = "Sponsors";
  let streamType = "YouTube";

$: if ($ws.message?.type === "state") {
    switch ($ws.message?.data) {
      case "Sponsors":
        currentView = "Sponsors";
        break;
      case "CurrentMatch":
        currentView = "CurrentMatch";
        break;
      default:
        currentView = "Sponsors";
    }
  }

$: if ($ws.message?.type == "stream") {
    switch ($ws.message?.data) {
      case "YouTube":
        streamType = "YouTube";
        break;
      case "Twitch":
        streamType = "Twitch";
        break;
      default:
        streamType = "YouTube";
    }
  }
</script>

<main>
  {#if currentView === "Sponsors"}
      <Sponsors title="Sponsors Right" url="https://docs.google.com/presentation/d/e/2PACX-1vSToCZ6ksw75RaUtXSaVFaWlWYgFRwob0FOeRamLQrt9g-T5YBKuiYFoHSFrLfyPtXXAe8V3kbjpl86/embed?start=true&loop=true&delayms=7000&rm=minimal" />
  {:else if currentView === "CurrentMatch"}
      {#if streamType === "YouTube"}
          <YouTube videoID="dQw4w9WgXcQ" />
      {:else if streamType === "Twitch"}
          <Twitch channel="example_channel" />
      {/if}
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