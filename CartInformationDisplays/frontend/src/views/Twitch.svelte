<script lang="ts">
  export let channel: string;
</script>

<iframe
    title="Twitch Stream"
    src={"https://player.twitch.tv/?channel=" + channel + "&parent=localhost&autoplay=true&muted=true&controls=false"}
    height="100%"
    width="100%"
    allowfullscreen>
</iframe>