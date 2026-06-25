import { describe, expect, test } from 'vitest'
import { consumeSseBuffer, parseSseEvent } from './sse'

describe('SSE parsing', () => {
  test('reassembles the exact chunk pattern produced by the backend', () => {
    const raw = [
      'data:##\n\n',
      'data: \n\n',
      'data:测试\n\n',
      'data:标题\n\n',
      'data:\ndata:\n\n',
      'data:-\n\n',
      'data: A\n\n'
    ].join('')
    const chunks: string[] = []

    const rest = consumeSseBuffer(raw, (text) => chunks.push(text))

    expect(rest).toBe('')
    expect(chunks.join('')).toBe('## 测试标题\n- A')
  })

  test('keeps newlines from multiline data fields', () => {
    expect(parseSseEvent('data:\ndata:')).toBe('\n')
  })

  test('keeps an incomplete event in the buffer', () => {
    const chunks: string[] = []
    const rest = consumeSseBuffer('data:##\n\ndata:标', (text) => chunks.push(text))

    expect(chunks).toEqual(['##'])
    expect(rest).toBe('data:标')
  })
})
