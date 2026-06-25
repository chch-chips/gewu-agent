import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, describe, expect, test, vi } from 'vitest'
import App from './App.vue'

afterEach(() => {
  vi.restoreAllMocks()
})

describe('streamed Markdown DOM rendering', () => {
  test('does not show dangling hashes and finishes as a real heading', async () => {
    let streamController: ReadableStreamDefaultController<Uint8Array> | undefined
    const encoder = new TextEncoder()
    const stream = new ReadableStream<Uint8Array>({
      start(controller) {
        streamController = controller
      }
    })

    vi.stubGlobal(
      'fetch',
      vi.fn((input: RequestInfo | URL) => {
        const url = String(input)
        if (url.endsWith('/api/chat/config')) {
          return Promise.resolve(
            new Response(
              JSON.stringify({
                configured: true,
                model: 'deepseek-v4-flash',
                baseUrl: 'https://api.deepseek.com'
              }),
              { headers: { 'Content-Type': 'application/json' } }
            )
          )
        }

        return Promise.resolve(
          new Response(stream, {
            headers: { 'Content-Type': 'text/event-stream' }
          })
        )
      })
    )

    const wrapper = mount(App, {
      global: {
        stubs: {
          Icon: true
        }
      }
    })
    await flushPromises()

    await wrapper.get('#chat-input').setValue('输出测试 Markdown')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    streamController?.enqueue(encoder.encode('data:##\n\n'))
    await flushPromises()

    const assistantMessages = wrapper.findAll('.message.assistant .markdown-body')
    expect(assistantMessages).toHaveLength(2)
    expect(assistantMessages[1].text()).not.toContain('#')

    streamController?.enqueue(
      encoder.encode(
        [
          'data: \n\n',
          'data:测试\n\n',
          'data:标题\n\n',
          'data:\ndata:\n\n',
          'data:-\n\n',
          'data: A\n\n',
          'data:\ndata:\n\n',
          'data:```\ndata:\n\n',
          'data:#include\n\n',
          'data: <stdio.h>\n\n',
          'data:\ndata:\n\n',
          'data:```\n\n'
        ].join('')
      )
    )
    streamController?.close()
    await flushPromises()

    const rendered = wrapper.findAll('.message.assistant .markdown-body')[1]
    expect(rendered.find('h2').text()).toBe('测试标题')
    expect(rendered.find('li').text()).toBe('A')
    expect(rendered.find('pre code').text()).toContain('#include <stdio.h>')
    expect(rendered.text()).not.toContain('##')
  })
})
