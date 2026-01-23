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
    host: '0.0.0.0', // Listen on all addresses
    strictPort: true,
    allowedHosts: true, // Allow all hosts (new in Vite 5.1+)
    cors: true,
    proxy: {
      '/api': {
        target: 'http://vyana-backend:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
        secure: false,
      },
    },
  },
})
