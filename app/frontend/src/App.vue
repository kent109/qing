<script setup lang="ts">
import { onMounted, ref } from 'vue'

interface HelloResponse {
  message: string
  database: string
  timestamp: string
}

const data = ref<HelloResponse | null>(null)
const error = ref('')
const loading = ref(false)

async function load() {
  loading.value = true
  error.value = ''
  try {
    const response = await fetch('/api/hello')
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }
    data.value = (await response.json()) as HelloResponse
  } catch (e) {
    data.value = null
    error.value = e instanceof Error ? e.message : String(e)
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

<template>
  <main class="page">
    <h1>Qing</h1>
    <p class="subtitle">Vue 3 + TypeScript + Vite，经 Vite 代理请求后端 /api/hello</p>

    <section class="card">
      <p v-if="loading" class="muted">请求中…</p>
      <p v-else-if="error" class="error">请求失败：{{ error }}</p>
      <dl v-else-if="data">
        <div>
          <dt>message</dt>
          <dd>{{ data.message }}</dd>
        </div>
        <div>
          <dt>database</dt>
          <dd>{{ data.database }}</dd>
        </div>
        <div>
          <dt>timestamp</dt>
          <dd>{{ data.timestamp }}</dd>
        </div>
      </dl>
    </section>

    <button type="button" :disabled="loading" @click="load">重新请求</button>
  </main>
</template>
