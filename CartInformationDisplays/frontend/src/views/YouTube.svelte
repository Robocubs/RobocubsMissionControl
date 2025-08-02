<script lang="ts">
  export let videoID: string;
</script>

<iframe
    title="YouTube Video"
    src={"https://www.youtube-nocookie.com/embed/" + videoID + "?controls=0&autoplay=1&mute=1"}
    height="100%"
    width="100%"
    frameborder="0"
    scrolling="no"
    allowfullscreen>
</iframe>