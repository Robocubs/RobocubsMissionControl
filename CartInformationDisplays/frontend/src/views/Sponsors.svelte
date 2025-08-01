<script lang="ts">
    export let title: string;
    export let url: string;
</script>

<div style="height: 100%; width: 100%; position: relative; overflow: hidden;">
    <iframe
    title={title}
    src={url}
    width="100.3%"
    height="100.3%"
    style="border: none; display: block;"
    ></iframe>
</div>