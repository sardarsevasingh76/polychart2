class PolyCanvas
  # Simulates paper element of Raphael
  constructor: (dom, w, h) ->
    if dom.getContext then @context = dom.getContext '2d'
    else dom.polyGeom = @

    dom.width = w
    dom.height = h

    @items = []
    @_counter = 0

  _makeItem: (type, args) ->
    item = new PolyCanvasItem type, @_newId(), @, args
    @items.unshift item
    item

  _newId: () -> @_counter += 1

  rect: (args...) -> @_makeItem 'rect', args
  circle: (args...) ->  @_makeItem 'circle', args
  path: (args...) -> @_makeItem 'path', args
  text: (args...) -> @_makeItem 'text', args

  remove: (id) ->
    for item, i in @items
      if item.id is id
        return @items.splice i, 1

  toBack: (id) ->
    [item] = @remove id
    [bg] = @remove 1
    @items.push item
    @items.push bg
  toFront: (id) ->
    [item] = @remove id
    @items.unshift item

  _resetContext: () ->
    @context.fillStyle = '#000000'
    @context.strokeStyle = '#000000'
    @context.globalAlpha = 1
    @context.lineWidth = 0.5

  _stringToHex: (colour) ->
    switch colour
      when 'black' then '#000000'
      when 'white' then '#ffffff'
      when 'steelblue' then '#4692B4'
      else colour

class PolyCanvasItem
  constructor: (@type, @id, @canvas, args) ->
    @_attr = {}
    @_interact = {}
    @attr args

  # Sets the attr of some drawn thing
  attr: (args...) ->
    if args.length > 0 and _.isArray args[0]
      params = args[0]
      switch @type
        when 'rect'
          @_attr = _.extend @_attr, {x: params[0], y: params[1], width: params[2], height: params[3]}
        when 'circle'
          @_attr = _.extend @_attr, {x: params[0], y: params[1], r: params[2]}
        when 'path'
          @_attr = _.extend @_attr, {path: params[0]}
        when 'text'
          @_attr = _.extend @_attr, {x: params[0], y: params[1], text: params[2]}
        else throw poly.error.defn "Unknown geometry type!"
    else if args.length == 1 and _.isObject args[0]
      for key, val of args[0]
        @_attr[key] = val
    else if args.length == 2 and args[0]? and args[1]?
      @_attr[args[0]] = args[1]
    @

  remove: () -> @canvas.remove @id
  toBack: () -> @canvas.toBack(@id)
  toFront: () -> @canvas.toFront(@id)

  animate: (args...) -> @_attr.animate = args; @

  click: (handler) -> @_interact.click = handler
  drag: (onmove, onstart, onend) -> @_interact.drag = {onmove, onstart, onend}
  hover: (handler) -> @_interact.hover = handler
  data: (type, handler) ->
    @_interact.data ?= {}
    @_interact.data[type] = handler

  touchstart: (handler) -> @_interact.touchstart = handler
  touchend: (handler) -> @_interact.touchend = handler
  touchmove: (handler) -> @_interact.touchmove = handler
  touchcancel: (handler) -> @_interact.touchcancel = handler

poly.canvas = (dom, w, h) -> new PolyCanvas dom, w, h
