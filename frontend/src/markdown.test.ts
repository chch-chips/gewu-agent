import { describe, expect, test } from 'vitest'
import {
  hideIncompleteBlockMarker,
  normalizeMarkdown,
  renderMarkdown
} from './markdown'

describe('Markdown rendering', () => {
  test('keeps valid ATX heading levels without leaking hash characters', () => {
    expect(normalizeMarkdown('## 二级标题')).toBe('## 二级标题')
    expect(renderMarkdown('## 二级标题')).toBe('<h2>二级标题</h2>\n')
    expect(renderMarkdown('### 三级标题')).toBe('<h3>三级标题</h3>\n')
  })

  test('repairs compact headings and list markers emitted by a model', () => {
    expect(normalizeMarkdown('#标题')).toBe('# 标题')
    expect(normalizeMarkdown('-列表项')).toBe('- 列表项')
    expect(normalizeMarkdown('1.列表项')).toBe('1. 列表项')

    const html = renderMarkdown('#标题\n\n-列表项\n- 第二项\n\n1.第一项\n2. 第二项')
    expect(html).toMatch(/<h1>标题<\/h1>/)
    expect(html).toMatch(/<ul>/)
    expect(html).toMatch(/<ol>/)
  })

  test('does not reinterpret repeated markers as headings or lists', () => {
    expect(normalizeMarkdown('## 标题')).toBe('## 标题')
    expect(normalizeMarkdown('**粗体**')).toBe('**粗体**')
    expect(normalizeMarkdown('---')).toBe('---')
    expect(normalizeMarkdown('####### 文本')).toBe('####### 文本')
  })

  test('preserves fenced and indented code verbatim', () => {
    const markdown = [
      '```c',
      '#include <stdio.h>',
      '-Wall',
      '1.version',
      '```',
      '',
      '    # indented code'
    ].join('\n')

    expect(normalizeMarkdown(markdown)).toBe(markdown)

    const html = renderMarkdown(markdown)
    expect(html).toMatch(/#include &lt;stdio\.h&gt;/)
    expect(html).toMatch(/-Wall/)
    expect(html).toMatch(/1\.version/)
    expect(html).toMatch(/# indented code/)
  })

  test('keeps blockquotes and inline code working', () => {
    const html = renderMarkdown('> 引用内容\n\n这里有 `#inline` 和 `-flag`。')

    expect(html).toMatch(/<blockquote>/)
    expect(html).toMatch(/<code>#inline<\/code>/)
    expect(html).toMatch(/<code>-flag<\/code>/)
  })

  test('hides a heading marker while its streamed line is incomplete', () => {
    expect(hideIncompleteBlockMarker('##')).toBe('')
    expect(hideIncompleteBlockMarker('正文\n### ')).toBe('正文\n')
    expect(renderMarkdown('##', true)).not.toContain('#')
    expect(renderMarkdown('## 标题', true)).toBe('<h2>标题</h2>\n')
    expect(renderMarkdown('代码是 `##`', true)).toContain('<code>##</code>')
    expect(renderMarkdown('```\n##', true)).toContain('##')
  })
})
