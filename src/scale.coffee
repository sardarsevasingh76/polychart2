###
Scales
------
Scales are objects that can construct functions that takes a value from
the data, and returns another value that is suitable for rendering an
attribute of that value.
###
class Scale
  constructor: (params) ->
    @f = null
  make: (domain) ->
    @domain = domain
    @compare = poly.domain.compare(domain)
    if not domain
      return @_makeNone()
    switch domain.type
      when 'num' then return @_makeNum()
      when 'date' then return @_makeDate()
      when 'cat' then return @_makeCat()
  _makeNone: () ->
    throw poly.error.impl "You are using a scale that does not support null values" #bad msg?
  _makeNum: () ->
    throw poly.error.impl "You are using a scale that does not support numbers"
  _makeDate: () ->
    throw poly.error.impl "You are using a scale that does not support dates"
  _makeCat: () ->
    throw poly.error.impl "You are using a scale that does not support categories"
  tickType: () ->
    if not @domain
      return @_tickNone()
    switch @domain.type
      when 'num' then return @_tickNum()
      when 'date' then return @_tickDate()
      when 'cat' then return @_tickCat()
  _tickNone: () -> 'none'
  _tickNum: () -> 'num'
  _tickDate: () -> 'date'
  _tickCat: () -> 'cat'
  _identityWrapper: (y) -> (x) ->
      if _.isObject(x) and x.t is 'scalefn'
        if x.f is 'identity' then return x.v
      y x

###
Position Scales for the x- and y-axes
###
class PositionScale extends Scale
  constructor: (params) ->
    @f = null
    @finv = null
  make: (domain, @range, @space) ->
    if not _.isNumber @space
      @space = 0.05
    super(domain)
  _makeNone: () ->
    space = (@range.max - @range.min) * @space
    @f = @_NaNCheckWrap (value) =>
      if _.isObject(value)
        if value.f is 'identity' then return value.v
        if value.f is 'middle' then return @range.max/2 + @range.min/2
        if value.f is 'max' then return @range.max
        if value.f is 'min' then return @range.min
        if value.f is 'upper' and not value.m then return @range.max - space
        if value.f is 'lower' and not value.m then return @range.min + space
        width = (@range.max-@range.min-2*space) / value.m
        if value.f is 'upper' then return (@range.min+space) + (value.n+1)*width
        if value.f is 'lower' then return (@range.min+space) + value.n*width
      return @range.max/2 + @range.min/2
    @finv = () -> {}

  _NaNCheckWrap: (fn) -> (value) ->
    if not poly.isDefined(value)
      undefined
    else
      out = fn(value)
      if isNaN(out) or out is Infinity or out is -Infinity
        throw poly.error.scale "Scale outputed a value that is not finite."
      out
  _numWrapper: (domain, y) => @_NaNCheckWrap (value) =>
    # NOTE: the below spacing makes sure that animation in polar coordinates
    # behave as expected. Test with polar bar charts to see...
    if _.isObject(value)
      if value.t is 'scalefn'
        if value.f is 'identity' then return value.v
        if value.f is 'middle' then return y(value.v+domain.bw/2) #for log scale
        if value.f is 'max' then return @range.max + value.v
        if value.f is 'min' then return @range.min + value.v

        if value.f in ['upper', 'lower']
          upper = y(value.v+domain.bw)
          lower = y(value.v)
          space = (upper - lower) * @space # 5%. Sign matters!
          if value.f is 'upper' and not value.m then return upper - space
          if value.f is 'lower' and not value.m then return lower + space

          # DODGING PURPOSES
          #value.n < value.m
          width = (upper-lower-2*space) / value.m
          if value.f is 'upper' then return (lower+space) + (value.n+1)*width
          if value.f is 'lower' then return (lower+space) + value.n*width

      throw poly.error.input "Unknown object #{value} is passed to a scale"
    y(value)
  _dateWrapper: (domain, y) => @_NaNCheckWrap (value) =>
    if _.isObject(value)
      if value.t is 'scalefn'
        if value.f is 'identity' then return value.v
        if value.f is 'max' then return @range.max + value.v
        if value.f is 'min' then return @range.min + value.v

        if value.f in ['upper', 'middle', 'lower']
          _timeConversion = (n, timerange, lower = 0) =>
            m = moment.unix(value.v).startOf(timerange)
            m[timerange](n * Math.floor(m[timerange]()/n) + n * lower)
            m.unix()
          upper =
            switch domain.bw
              when 'week' then moment.unix(value.v).day(7).unix()
              when 'twomonth' then _timeConversion 2, 'month'
              when 'quarter' then _timeConversion 4, 'month'
              when 'sixmonth' then _timeConversion 6, 'month'
              when 'twoyear' then _timeConversion 2, 'year'
              when 'fiveyear' then _timeConversion 5, 'year'
              when 'decade' then _timeConversion 10, 'year'
              else moment.unix(value.v).endOf(domain.bw).unix()
          upper = y(upper)
          lower =
            switch domain.bw
              when 'week' then moment.unix(value.v).day(0).unix()
              when 'twomonth' then _timeConversion 2, 'month', 1
              when 'quarter' then _timeConversion 4, 'month', 1
              when 'sixmonth' then _timeConversion 6, 'month', 1
              when 'twoyear' then _timeConversion 2, 'year', 1
              when 'fiveyear' then _timeConversion 5, 'year', 1
              when 'decade' then _timeConversion 10, 'year', 1
              else moment.unix(value.v).startOf(domain.bw).unix()
          lower = y(lower)
          space = (upper - lower) * @space # 5%. Sign matters!
          if value.f is 'middle' then return upper/2 + lower/2
          if value.f is 'upper' and not value.m then return upper - space
          if value.f is 'lower' and not value.m then return lower + space

          # DODGING PURPOSES
          #value.n < value.m
          width = (upper-lower-2*space) / value.m
          if value.f is 'upper' then return (lower+space) + (value.n+1)*width
          if value.f is 'lower' then return (lower+space) + value.n*width
      throw poly.error.input "Unknown object #{value} is passed to a scale"
    y(value)
  _catWrapper: (step, y) => @_NaNCheckWrap (value) =>
    space = step * @space
    if _.isObject(value)
      if value.t is 'scalefn'
        if value.f is 'identity' then return value.v
        if value.f is 'max' then return @range.max + value.v
        if value.f is 'min' then return @range.min + value.v

        if value.f in ['upper', 'middle', 'lower']
          upper = y(value.v) + step
          lower = y(value.v)
          if value.f is 'middle' then return upper/2 + lower/2
          if value.f is 'upper' and not value.m then return upper - space
          if value.f is 'lower' and not value.m then return lower + space

          # DODGING PURPOSES
          #value.n < value.m
          width = (upper-lower-2*space) / value.m
          if value.f is 'upper' then return (lower+space) + (value.n+1)*width
          if value.f is 'lower' then return (lower+space) + value.n*width

      throw poly.error.input "Unknown object #{value} is passed to a scale"
    y(value) + step/2

class Linear extends PositionScale
  _makeNum: () ->
    y = poly.linear(@domain.min, @range.min, @domain.max, @range.max)
    x = poly.linear(@range.min, @domain.min, @range.max, @domain.max)
    @f = @_numWrapper @domain, y
    @finv = (y1, y2) ->
      xs = [x(y1),x(y2)]
      {ge: _.min(xs), le: _.max(xs)}
  _makeDate: () ->
    y = poly.linear(@domain.min, @range.min, @domain.max, @range.max)
    x = poly.linear(@range.min, @domain.min, @range.max, @domain.max)
    @f = @_dateWrapper @domain, y
    @finv = (y1, y2) ->
      xs = [x(y1),x(y2)]
      {ge: _.min(xs), le: _.max(xs)}
  _makeCat: () ->
    step = (@range.max - @range.min) / @domain.levels.length
    y = (x) =>
      i = _.indexOf(@domain.levels, x)
      if i == -1 then null else @range.min + i*step
    x = (y1, y2) =>
      if y2 < y1 then [y1, y2] = [y2, y1]
      i1 = Math.floor(y1/step)
      i2 = Math.floor(y2/step)
      {in: @domain.levels[i1..i2]}
    @f = @_catWrapper step, y
    @finv = x

class Log extends PositionScale
  _makeNum: () ->
    if @domain.min < 0
      throw poly.error.input "Log scale cannot handle zero or negative input."
    lg = Math.log
    ylin = poly.linear lg(@domain.min), @range.min, lg(@domain.max), @range.max
    @f = @_numWrapper @domain, (x) -> ylin lg(x)

    ylininv = poly.linear @range.min, lg(@domain.min), @range.max, lg(@domain.max)
    x = (y) -> Math.exp(ylininv(y))
    @finv = (y1, y2) ->
      xs = [x(y1),x(y2)]
      {ge: _.min(xs), le: _.max(xs)}
  _tickNum: () -> 'num-log'

###
Other, legend-type scales for the x- and y-axes
###
class Area extends Scale
  _makeNum: () => #range = [0, 1]
    min = if @domain.min == 0 then 0 else 1
    sq = Math.sqrt
    ylin = poly.linear sq(@domain.min), min, sq(@domain.max), 10
    @f = @_identityWrapper (x) -> ylin sq(x)
  _makeDate: () => @_makeNum()

class Opacity extends Scale
  _makeNum: () => #range = [0, 1]
    min = if @domain.min == 0 then 0 else 0.1
    max = 1
    @f = @_identityWrapper poly.linear(@domain.min, min, @domain.max, max)
  _makeDate: () => @_makeNum()

class Palette extends Scale
  _makeCat: () => #TEMPORARY
    n = @domain.levels.length
    if n <= 9
      colors = ["#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00",
        "#FFFF33", "#A65628", "#F781BF", "#999999"]
      @f = (value) =>
        i = _.indexOf(@domain.levels, value)
        colors[i]
    else
      h = (v) => _.indexOf(@domain.levels, v) / n + 1/(2*n)
      @f = (value) =>
        Raphael?.hsl(h(value),0.5,0.5) ? "hsl(#{h(value)},0.5,0.5)"

class Gradient extends Scale
  constructor: (params) ->
    {@lower, @upper} = params
  _makeNum: () =>
    lower = Raphael?.color(@lower) ? @lower
    upper = Raphael?.color(@upper) ? @upper
    r = poly.linear @domain.min, lower.r, @domain.max, upper.r
    g = poly.linear @domain.min, lower.g, @domain.max, upper.g
    b = poly.linear @domain.min, lower.b, @domain.max, upper.b
    @f =
      @_identityWrapper (value) =>
        Raphael?.rgb r(value), g(value), b(value) ? "rgb(#{r(value)}, #{g(value)}, #{b(value)})"
  _makeDate: () => @_makeNum()

class Gradient2 extends Scale
  constructor: (params) ->
    {@lower, @middle, @upper, @midpoint} = params
    @midpoint ?= 0
  _makeNum: () =>
    lower = Raphael?.color(@lower) ? @lower
    middle = Raphael?.color(@middle) ? @middle
    upper = Raphael?.color(@upper) ? @upper
    r1 = poly.linear @domain.min, lower.r, @midpoint, middle.r
    g1 = poly.linear @domain.min, lower.g, @midpoint, middle.g
    b1 = poly.linear @domain.min, lower.b, @midpoint, middle.b
    r2 = poly.linear @midpoint, middle.r, @domain.max, upper.r
    g2 = poly.linear @midpoint, middle.g, @domain.max, upper.g
    b2 = poly.linear @midpoint, middle.b, @domain.max, upper.b
    @f =
      @_identityWrapper (value) =>
        if value < @midpoint
          Raphael?.rgb(r1(value), g1(value), b1(value)) ? "rgb(#{r1(value)}, #{g1(value)}, #{b1(value)})"
        else
          Raphael?.rgb r2(value), g2(value), b2(value)  ? "rgb(#{r2(value)}, #{g2(value)}, #{b2(value)})"
  _makeCat: () =>
  _makeDate: () => @_makeNum()

class CustomScale extends Scale
  constructor: (params) -> {@function} = params
  make: (domain) ->
    @domain = domain
    @compare = poly.domain.compare(domain)
    @f = @_identityWrapper @function

class Shape extends Scale
  _makeCat: () ->

class Identity extends Scale
  make: (domain) ->
    @domain = domain
    @compare = (a, b) -> 0
    @f = @_identityWrapper (x) -> x

###
Public interface to making different scales
###
poly.scale = {}
poly.scale.Base = Scale
poly.scale.classes = {
  linear : Linear
  log : Log
  area : Area
  palette : Palette
  gradient : Gradient
  gradient2 : Gradient2
  identity: Identity
  opacity: Opacity
  custom: CustomScale
}
poly.scale.make = (spec) ->
  type = spec.type
  if type of poly.scale.classes
    return new poly.scale.classes[type](spec)
  throw poly.error.defn "No such scale #{spec.type}."
