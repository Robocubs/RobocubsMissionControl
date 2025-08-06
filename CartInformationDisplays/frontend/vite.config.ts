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
      '/cartL': {
        target: 'ws://localhost:8010',
        ws: true,
      },
      '/cartR': {
        target: 'ws://localhost:8010',
        ws: true,
      },
      '/api': 'http://localhost:8010'
    }
  }
})
