import MarkdownIt from 'markdown-it'

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

export function renderMarkdown(content: string, streaming = false) {
  const source = streaming ? hideIncompleteBlockMarker(content) : content
  return markdown.render(normalizeMarkdown(source || '正在思考...'))
}

export function normalizeMarkdown(content: string) {
  const lines = content.split(/\r?\n/)
  let fenceMarker = ''
  let fenceLength = 0

  return lines
    .map((line) => {
      const fence = line.match(/^ {0,3}(`{3,}|~{3,})/)

      if (fenceMarker) {
        if (
          fence &&
          fence[1][0] === fenceMarker &&
          fence[1].length >= fenceLength &&
          line.slice(fence[0].length).trim() === ''
        ) {
          fenceMarker = ''
          fenceLength = 0
        }
        return line
      }

      if (fence) {
        fenceMarker = fence[1][0]
        fenceLength = fence[1].length
        return line
      }

      if (/^(?: {4}|\t)/.test(line)) {
        return line
      }

      return line
        .replace(/^( {0,3})(#{1,6})(?=[^#\s])/, '$1$2 ')
        .replace(/^( {0,3})([-*+])(?=[^\s\-*+])/, '$1$2 ')
        .replace(/^( {0,3})(\d{1,9}\.)(?=[^\d\s.])/, '$1$2 ')
    })
    .join('\n')
}

export function hideIncompleteBlockMarker(content: string) {
  const lines = content.split(/\r?\n/)
  const lastLineIndex = lines.length - 1
  let fenceMarker = ''
  let fenceLength = 0

  for (const line of lines) {
    const fence = line.match(/^ {0,3}(`{3,}|~{3,})/)

    if (fenceMarker) {
      if (
        fence &&
        fence[1][0] === fenceMarker &&
        fence[1].length >= fenceLength &&
        line.slice(fence[0].length).trim() === ''
      ) {
        fenceMarker = ''
        fenceLength = 0
      }
      continue
    }

    if (fence) {
      fenceMarker = fence[1][0]
      fenceLength = fence[1].length
    }
  }

  if (!fenceMarker && /^ {0,3}#{1,6}\s*$/.test(lines[lastLineIndex])) {
    lines[lastLineIndex] = ''
  }

  return lines.join('\n')
}
