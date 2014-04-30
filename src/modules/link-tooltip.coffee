_       = require('lodash')
DOM     = require('../dom')
Tooltip = require('./tooltip')


class LinkTooltip extends Tooltip
  @DEFAULTS:
    styles:
      '.link-tooltip-container a': {
        'cursor': 'pointer'
        'text-decoration': 'none'
      }
      '.link-tooltip-container > a, .link-tooltip-container > span': {
        'display': 'inline-block'
        'line-height': '24px'
      }
      '.link-tooltip-container .input'          : { 'display': 'none', 'width': '170px' }
      '.link-tooltip-container .done'           : { 'display': 'none' }
      '.link-tooltip-container.editing .input'  : { 'display': 'inline-block' }
      '.link-tooltip-container.editing .done'   : { 'display': 'inline-block' }
      '.link-tooltip-container.editing .url'    : { 'display': 'none' }
      '.link-tooltip-container.editing .change' : { 'display': 'none' }
    template:
     '<span class="title">Visit URL:&nbsp;</span>
      <a href="#" class="url" target="_blank" href="about:blank"></a>
      <input class="input" type="text">
      <span>&nbsp;&#45;&nbsp;</span>
      <a href="javascript:;" class="change">Change</a>
      <a href="javascript:;" class="done">Done</a>'

  constructor: (@quill, @editorContainer, @options) ->
    @options.styles = _.defaults(@options.styles, Tooltip.DEFAULTS.styles)
    super(@quill, @editorContainer, @options)
    @options = _.defaults(@options, Tooltip.DEFAULTS)
    DOM.addClass(@container, 'link-tooltip-container')
    @textbox = @container.querySelector('.input')
    @link = @container.querySelector('.url')
    this.initToolbar()
    this.initListeners()

  initListeners: ->
    @quill.on(@quill.constructor.events.SELECTION_CHANGE, (range) =>
      return unless range? and range.isCollapsed()
      index = Math.max(0, range.start - 1)
      [line, offset] = @quill.editor.doc.findLineAt(index)
      return unless line?
      [leaf, offset] = line.findLeafAt(offset)
      node = leaf.node
      while node?
        if node.tagName == 'A'
          this.setMode(node.href, false)
          this.show(node)
          return
        else
          node = node.parentNode
      this.hide()
    )
    DOM.addEventListener(@container.querySelector('.done'), 'click', _.bind(this.saveLink, this))
    DOM.addEventListener(@textbox, 'keyup', (event) =>
      this.saveLink() if event.which == DOM.KEYS.ENTER
    )
    DOM.addEventListener(@container.querySelector('.change'), 'click', =>
      this.setMode(@link.href, true)
    )

  initToolbar: ->
    @quill.onModuleLoad('toolbar', (toolbar) =>
      toolbar.initFormat('link', 'click', (range, value) =>
        if value
          this.setMode(this._suggestURL(range), true)
          nativeRange = @quill.editor.selection._getNativeRange()
          this.show(nativeRange)
        else
          @quill.formatText(range, 'link', false, 'user')
      )
    )

  saveLink: ->
    url = this._normalizeURL(@textbox.value)
    @quill.formatText(@range, 'link', url) if @range?
    this.setMode(url, false)

  setMode: (url, edit = false) ->
    if edit
      @textbox.value = url
      @textbox.focus()
      _.defer( =>
        @textbox.setSelectionRange(url.length, url.length)
      )
    else
      @link.href = url
      DOM.setText(@link, url)
    DOM.toggleClass(@container, 'editing', edit)

  _normalizeURL: (url) ->
    url = 'http://' + url unless /^https?:\/\//.test(url)
    return url

  _suggestURL: (range) ->
    text = @quill.getText(range)
    return this._normalizeURL(text)


module.exports = LinkTooltip
