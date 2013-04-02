touchInfo = {
  touches: []
  lastStart: 0
  lastTouch: 0
  sinceLastTouch: 0
}

# Current issues:
#   * The wrapping hack with zoom does not work with this
#   * There seems to be some delay in handler updating---in particular, 'touchmove' sometimes fires after 'touchend'
poly.touch = (type, obj, event, graph) =>
  # Helper to average over points, incase of multi touch
  _updatePt = (oldPt, newPt) ->
    if oldPt?
      oldPt.x = (oldPt.x + newPt.x)/2
      oldPt.y = (oldPt.y + newPt.y)/2
    else
      oldPt = x: newPt.x, y: newPt.y
    oldPt
  touchList = event.changedTouches
  first = touchList[0]
  if type is 'touchstart'
    touchInfo.sinceLastTouch = event.timeStamp - touchInfo.lastTouch
    touchInfo.lastStart = event.timeStamp
    for i in [0..touchList.length-1]
      touchInfo.touches.push
        x: touchList[i].screenX
        y: touchList[i].screenY
        id: touchList[i].identifier
        time: event.timeStamp
    ['touchstart']
  else if type is 'touchmove'
    event.preventDefault()
    elem = graph.paper.getById event.target.raphaelid
    offset = poly.offset graph.dom
    touchPos = poly.getXY offset, event
    if event.timeStamp - touchInfo.lastStart > 500
      if elem.isPointInside(touchPos.x, touchPos.y) then ['touchmove','mover'] else ['touchmove', 'mout']
    else
      ['touchmove']
  else if type is 'touchend'
    event.preventDefault()
    obj.tooltip = obj.data('t')
    obj.evtData = obj.data('e')

    start = end = null
    touchTime = 0
    for i in [0..touchList.length-1]
      touch =
        x: touchList[i].screenX
        y: touchList[i].screenY
        id: touchList[i].identifier
        time: event.timeStamp
      _updatePt end, touch
      for j in [touchInfo.touches.length-1..0]
        if touchInfo.touches[j].id == touch.id
          touchTime = Math.max touchTime, touch.time - touchInfo.touches[j].time
          _updatePt start, touchInfo.touches[j]
          touchInfo.touches.splice(j, 1)
    touchInfo.lastTouch = event.timeStamp
    if touchTime < 500
      touchType = 'tap'
    else if touchTime < 800
      touchType = 'touch'
    else
      touchType = 'hold'
    possibleEvents = (e.name for e in obj.events)
    if 'mouseover' not in possibleEvents # Bad heuristic for background
      ['reset','mout']
    else if 'mouseover' in possibleEvents and touchType is 'tap'
      ['mout','click']
    else
      ['mout']
  else if type is 'touchcancel'
    ['reset','mout']
