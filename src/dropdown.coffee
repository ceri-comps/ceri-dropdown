ceri = require "ceri/lib/wrapper"
module.exports = ceri

  mixins: [
    require "ceri/lib/props"
    require "ceri/lib/computed"
    require "ceri/lib/styles"
    require "ceri/lib/events"
    require "ceri/lib/animate"
    require "ceri/lib/open"
    require "ceri/lib/getViewportSize"
    require "ceri/lib/@popstate"
  ]

  props:
    keepOpen:
      type: Boolean
    constrainWidth:
      type: Boolean
    overlay:
      type: Boolean
    gutter:
      type: Number
      default: 0
    anchor:
      type: String
    onBody:
      type: Boolean
    hover:
      type: Boolean

  data: ->
    active: false
    position: 
      top: null
      left: null

  events:
    popstate:
      active: -> @active and @onBody
      cbs: -> @hide(false)
    mouseover:
      el: "target"
      active: -> @hover and !@active
      cbs: "show"
      destroy: true
    mouseleave:
      active: -> @hover and @active
      cbs: "hide"

    click:
      target:
        active: -> !@hover and !@active
        notPrevented: true
        prevent: true
        cbs: "show"
        destroy: true
      this:
        notPrevented: true
        prevent: true
        cbs: "hide"
      outside: 
        el: document.documentElement
        outside: true
        cbs: "hide"
        active: "active"
        delay: true
        destroy: true
    
    keyup:
      el:document.documentElement
      notPrevented: true
      destroy: true
      keyCode: [27]
      active: "active"
      cbs: "hide"
      
  styles:
    this:
      data: ->
        position: "absolute"
        display: "block"
      computed: ->
        width: [@width,"px"]
        boxSizing: if @width then "border-box" else null
        left: [@position.left,"px"]

  computed:
    cAnchor: ->
      return @anchor if @anchor
      return "nw" if @overlay
      return "sw"
    target: ->
        if @__placeholder.previousElementSibling
          return @__placeholder.previousElementSibling
        else
          return @__parentElement
    totalWidth: ->
      if @constrainWidth
        return @target.offsetWidth-@gutter
      else
        return @offsetWidth+@gutter
    width: ->
      return @totalWidth if @constrainWidth
      return null
    totalHeight: ->
      if @overlay
        return @offsetHeight 
      else
        return @offsetHeight + @target.offsetHeight
  methods:

    enter: (o) ->
      o.preserve = ["overflow","height"]
      o.init = overflow: "hidden"
      o.style = 
        height: [0,@offsetHeight, "px"]
        opacity: [0,1]
      if @position.asTop
        o.init.top = @position.top + "px"
      else
        o.style.top = [@position.top+@offsetHeight,@position.top, "px"]
      return @$animate(o)

    leave: (o) ->
      o.preserve = ["overflow","height"]
      o.init = overflow: "hidden"
      o.duration = 200
      o.style =
        height: [@offsetHeight,0, "px"]
        opacity: [1,0]
      unless @position.asTop
        o.style.top = [@position.top, @position.top+@offsetHeight, "px"]
      return @$animate(o)

    show: (animate) ->
      return if @open and not @closing
      @active = true
      unless @closing
        if @onBody
          document.body.appendChild @
        @setOpen()
        @getPosition()
      else
        @closing = false
      @animation = @enter @$cancelAnimation @animation, animate: animate

    hide: (animate) ->
      return unless @open
      @active = false
      @closing = true
      @animation = @leave @$cancelAnimation @animation,
        animate: animate
        done: -> 
          @closing = false
          @setClose()
          if @onBody
            @remove()

    toggle: (animate) ->
      if @open
        @hide(animate)
      else
        @show(animate)

    getPosition: ->
      targetPos = @target.getBoundingClientRect()
      windowSize = @getViewportSize()

      asTop = true
      if (@cAnchor[0] == "n" and @overlay) or (@cAnchor[0] == "s" and not @overlay)
        asTop = targetPos.top + @totalHeight < windowSize.height
      else
        asTop = targetPos.bottom - @totalHeight < 0

      asLeft = true
      if @cAnchor[1] == "e"
        asLeft = targetPos.right - @totalWidth < 0
      else
        asLeft = targetPos.left + @totalWidth < windowSize.width

      top = if asTop then 0 else -@totalHeight 
      top += @target.offsetHeight unless asTop and @overlay

      left = 0
      if asLeft
        left += @gutter
      else
        left -= @totalWidth - @target.offsetWidth

      if @onBody
        body = document.body
        docEl = document.documentElement
        scrollTop = window.pageYOffset || docEl.scrollTop || body.scrollTop
        scrollLeft = window.pageXOffset || docEl.scrollLeft || body.scrollLeft
        top += scrollTop + targetPos.top
        left += scrollLeft + targetPos.left
      else
        if @parentElement != @target or not /relative|absolute|fixed/.test(getComputedStyle(@parentElement).getPropertyValue("position"))
          top += @target.offsetTop
          left += @target.offsetLeft
      @position = top: top, left: left, asTop: asTop 

  