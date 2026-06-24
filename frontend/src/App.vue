<script setup lang="ts">
import MarkdownIt from 'markdown-it'
import { computed, onMounted, ref } from 'vue'
import { Icon } from '@iconify/vue'

type ChatConfig = {
  configured: boolean
  model: string
  baseUrl: string
}

type Message = {
  id: number
  role: 'user' | 'assistant'
  content: string
  state?: 'normal' | 'error'
}

const apiBase = import.meta.env.VITE_API_BASE_URL ?? ''
const config = ref<ChatConfig | null>(null)
const messages = ref<Message[]>([
  {
    id: 1,
    role: 'assistant',
    content: '我在。你可以直接问 Spring AI、项目配置，或者让当前模型帮你拆解一个问题。'
  }
])
const input = ref('')
const selectedModel = ref('deepseek-v4-flash')
const loading = ref(false)
const error = ref('')

const markdown = new MarkdownIt({
  html: false,
  linkify: true,
  typographer: true,
  breaks: true
})

markdown.renderer.rules.link_open = (tokens, idx, options, env, self) => {
  const token = tokens[idx]
  token.attrSet('target', '_blank')
  token.attrSet('rel', 'noopener noreferrer')
  return self.renderToken(tokens, idx, options)
}

const modelOptions = [
  { value: 'deepseek-v4-flash', label: 'v4 flash' },
  { value: 'deepseek-v4-pro', label: 'v4 pro' }
]

const statusText = computed(() => {
  if (!config.value) return '检查中'
  return config.value.configured ? '已接入 DeepSeek' : '还没配置 Key'
})

async function loadConfig() {
  error.value = ''
  try {
    const response = await fetch(`${apiBase}/api/chat/config`)
    if (!response.ok) throw new Error('后端没有响应，请确认 8080 服务已经启动。')
    config.value = await response.json()
    selectedModel.value = config.value?.model || 'deepseek-v4-flash'
  } catch (err) {
    error.value = err instanceof Error ? err.message : '配置读取失败，请稍后重试。'
  }
}

async function sendMessage() {
  const content = input.value.trim()
  if (!content || loading.value) return

  const userMessage: Message = {
    id: Date.now(),
    role: 'user',
    content
  }
  const assistantMessage: Message = {
    id: Date.now() + 1,
    role: 'assistant',
    content: ''
  }

  messages.value.push(userMessage, assistantMessage)
  input.value = ''
  loading.value = true
  error.value = ''

  try {
    await sendStream(content, assistantMessage)
  } catch (err) {
    const message = err instanceof Error ? err.message : '流式连接中断，请稍后重试。'
    assistantMessage.state = 'error'
    assistantMessage.content = assistantMessage.content
      ? `${assistantMessage.content}\n\n> ${message}`
      : `流式接口暂时不可用。\n\n${message}\n\n请检查后端日志或稍后重试。`
    error.value = message
  } finally {
    loading.value = false
  }
}

async function sendStream(content: string, assistantMessage: Message) {
  const response = await fetch(`${apiBase}/api/chat/stream`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: content,
      model: selectedModel.value
    })
  })

  if (!response.ok || !response.body) {
    const payload = await response.json().catch(() => null)
    throw new Error(payload?.message ?? '流式接口没有接通，请确认后端与模型服务状态。')
  }

  const reader = response.body.getReader()
  const decoder = new TextDecoder('utf-8')
  let buffer = ''

  while (true) {
    const { done, value } = await reader.read()
    if (done) break

    buffer += decoder.decode(value, { stream: true })
    buffer = consumeSseBuffer(buffer, assistantMessage)
  }

  buffer += decoder.decode()
  consumeSseBuffer(`${buffer}\n\n`, assistantMessage)
}

function consumeSseBuffer(buffer: string, assistantMessage: Message) {
  const events = buffer.split(/\r?\n\r?\n/)
  const rest = events.pop() ?? ''

  for (const event of events) {
    const text = parseSseEvent(event)
    if (text !== '' && text.trim() !== '[DONE]') {
      assistantMessage.content += text
    }
  }

  return rest
}

function parseSseEvent(event: string) {
  return event
    .split(/\r?\n/)
    .filter((line) => line.startsWith('data:'))
    .map((line) => line.slice('data:'.length))
    .join('\n')
}

function renderMarkdown(content: string) {
  return markdown.render(normalizeMarkdown(content || '正在思考...'))
}

function normalizeMarkdown(content: string) {
  return content
    .replace(/^(#{1,6})(?=\S)/gm, '$1 ')
    .replace(/^(\s*[-*+])(?=\S)/gm, '$1 ')
    .replace(/^(\s*\d+\.)(?=[^\d\s])/gm, '$1 ')
}

onMounted(loadConfig)
</script>

<template>
  <main class="workspace">
    <aside class="rail">
      <div class="brand">
        <span class="brand-mark">G</span>
        <div>
          <strong>Gewu Agent</strong>
          <small>阶段 0</small>
        </div>
      </div>

      <section class="status-block">
        <span class="status-dot" :class="{ on: config?.configured }"></span>
        <div>
          <strong>{{ statusText }}</strong>
          <small>{{ config?.baseUrl || 'localhost' }}</small>
        </div>
      </section>

      <label class="field">
        <span>模型</span>
        <select v-model="selectedModel">
          <option v-for="model in modelOptions" :key="model.value" :value="model.value">
            {{ model.label }}
          </option>
        </select>
      </label>
    </aside>

    <section class="chat-panel">
      <header class="chat-head">
        <div>
          <p>DeepSeek 聊天</p>
          <h1>先把话说通。</h1>
        </div>
        <button class="ghost" type="button" aria-label="刷新配置状态" @click="loadConfig">
          <Icon icon="lucide:refresh-cw" />
          刷新
        </button>
      </header>

      <div class="messages" aria-live="polite">
        <article
          v-for="message in messages"
          :key="message.id"
          class="message"
          :class="[message.role, message.state]"
        >
          <span>{{ message.role === 'user' ? '你' : 'Agent' }}</span>
          <div
            v-if="message.role === 'assistant'"
            class="message-body markdown-body"
            v-html="renderMarkdown(message.content)"
          ></div>
          <p v-else class="message-body">{{ message.content }}</p>
        </article>
      </div>

      <form class="composer" @submit.prevent="sendMessage">
        <textarea
          id="chat-input"
          v-model="input"
          rows="3"
          aria-label="聊天输入"
          placeholder="问点具体的，比如：帮我解释 Spring AI 2.0 的 ChatClient"
          @keydown.enter.exact.prevent="sendMessage"
        />
        <button class="send" type="submit" :disabled="loading || !input.trim()">
          <Icon :icon="loading ? 'lucide:loader-circle' : 'lucide:send-horizontal'" />
          {{ loading ? '发送中' : '发送' }}
        </button>
      </form>

      <p v-if="error" class="error" role="alert">{{ error }}</p>
    </section>

    <aside class="note-panel">
      <h2>启动前看一眼</h2>
      <p>API Key 只放后端。</p>
      <code>DEEPSEEK_API_KEY</code>
      <p>默认模型是 flash。</p>
      <code>deepseek-v4-flash</code>
      <p>复杂任务再切 pro。</p>
      <code>deepseek-v4-pro</code>
    </aside>
  </main>
</template>
