<script lang="ts">
  import Sponsors from "./views/Sponsors.svelte";
  import CurrentMatch from "./views/CurrentMatch.svelte";

  import createWebsocketTunnel from "./websocketTunnel";

  const ws = createWebsocketTunnel("ws://localhost:8010/cartL");

  let currentView = "Sponsors";

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
</script>

<main>
  {#if currentView === "Sponsors"}
      <Sponsors title="Sponsors Left" url="https://docs.google.com/presentation/d/e/2PACX-1vRkkyssQQCfxNXfz6p63vJQFkNowBuO5IQGxcVh7oHx7nSDiTy5q7LhW3oDdxhHp548xx8ZUKeW0umM/embed?start=true&loop=true&delayms=7000&rm=minimal" />
  {:else if currentView === "CurrentMatch"}
      <CurrentMatch />
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