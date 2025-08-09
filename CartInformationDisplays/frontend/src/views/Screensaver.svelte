<script lang="ts">
  export let position: string;
</script>

<div>
    <style>
        .fullscreen-img {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            object-fit: contain; /* or cover */
            z-index: 9999; /* Optional: to ensure no gaps */
        }
    </style>

<img src={`/prod/pitCart-${position}.png`} alt="Screensaver" class="fullscreen-img" />
</div>