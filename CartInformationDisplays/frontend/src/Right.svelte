<script lang="ts">
  import Sponsors from "./views/Sponsors.svelte";
  import YouTube from "./views/YouTube.svelte";
  import Twitch from "./views/Twitch.svelte";

  import createWebsocketTunnel from "./websocketTunnel";

  const ws = createWebsocketTunnel("ws://localhost:8010/cartR");

  let currentView = "sponsors";
  let streamType = "YouTube";

$: if ($ws.message?.type === "state") {
    switch ($ws.message?.data) {
      case "sponsors":
        currentView = "sponsors";
        break;
      case "currentMatch":
        currentView = "currentMatch";
        break;
      default:
        currentView = "sponsors";
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
  {#if currentView === "sponsors"}
      <Sponsors title="Sponsors Right" url="https://docs.google.com/presentation/d/e/2PACX-1vSToCZ6ksw75RaUtXSaVFaWlWYgFRwob0FOeRamLQrt9g-T5YBKuiYFoHSFrLfyPtXXAe8V3kbjpl86/embed?start=true&loop=true&delayms=7000&rm=minimal" />
  {:else if currentView === "currentMatch"}
      {#if streamType === "YouTube"}
          <YouTube videoID="tTc_SdbR1Fg" />
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