import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

// https://vite.dev/config/
export default defineConfig({
  base: '/prod/',
  plugins: [svelte()],
  publicDir: '../assets',
  build: {
    outDir: '../frontend/prod',
    rollupOptions: {
      input: {
        left: 'left.html',
        right: 'right.html',
      },
    },
  },
  server: {
    proxy: {
      // main.py/uvicorn actually serves on 1701 (see requirements.txt /
      // missionControlServer.service) — 8010 here was stale and pointed
      // dev-server websockets/API calls nowhere.
      '/cartL': {
        target: 'ws://localhost:1701',
        ws: true,
      },
      '/cartR': {
        target: 'ws://localhost:1701',
        ws: true,
      },
      '/api': 'http://localhost:1701',
      '/media': 'http://localhost:1701'
    }
  }
})
