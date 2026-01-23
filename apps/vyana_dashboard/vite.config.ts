import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 9488,
    strictPort: true,
    host: true,
    allowedHosts: ['all', 'vyana.suryaprakashinfo.in', '103.194.228.99', 'localhost'],
    cors: true,
    hmr: {
      clientPort: 9488,
    },
    proxy: {
      '/api': {
        target: 'http://vyana-backend:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
})
