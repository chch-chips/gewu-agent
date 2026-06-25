export function parseSseEvent(event: string) {
  return event
    .split(/\r?\n/)
    .filter((line) => line.startsWith('data:'))
    .map((line) => line.slice('data:'.length))
    .join('\n')
}

export function consumeSseBuffer(buffer: string, onText: (text: string) => void) {
  const events = buffer.split(/\r?\n\r?\n/)
  const rest = events.pop() ?? ''

  for (const event of events) {
    const text = parseSseEvent(event)
    if (text !== '' && text.trim() !== '[DONE]') {
      onText(text)
    }
  }

  return rest
}
