<script lang="ts">
  export let position: string;
  let loaded = false;
  let imgSrc = `/prod/pitCart-${position}.png`;
</script>

<style>
  .screensaver-bg {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: black;
    z-index: 9998;
  }
  .fullscreen-img {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    object-fit: contain;
    z-index: 9999;
    opacity: 0;
    transition: opacity 0.1s;
  }
  .fullscreen-img.loaded {
    opacity: 1;
    transition: opacity 0.1s;
  }
</style>

<div class="screensaver-bg"></div>
<img
  src={imgSrc}
  alt="Screensaver"
  class="fullscreen-img"
  class:loaded={loaded}
  on:load={() => (loaded = true)}
/>