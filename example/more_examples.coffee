@examples ?= {}

@examples.content_bars = (dom) ->
  data = polyjs.data {data: content, meta: {dataset_id: {type: 'num'}, user_id: {type: 'num'}, public: {type: 'cat'}}}
  spec = {
    layers: [
      {data : data, type: 'bar', x: 'bin(dataset_id, 100)', y: 'public', color: 'count(user_id)'}
    ]
    dom: dom
  }
  c = polyjs.chart spec

@examples.email_bars = (dom) ->
  data = polyjs.data {data: emails, meta: {created: {type: 'date'}, id: {type: 'num'}}}
  spec = {
    width: 900
    layers: [
      {data: data, type: 'bar', x: 'bin(created, day)', y: 'count(id)'}
    ]
    dom: dom
  }
  c = polyjs.chart spec


###
This is a rather interesting example. What do we really expect in this case?
###
@examples.email_pie = (dom) ->
  data = polyjs.data {data: emails, meta: {created: {type: 'date'}, success: {type: 'cat'}}}
  spec = {
    layers: [
      {data: data, type: 'bar', y: 'created', color: 'success'}
    ]
    coord:{ type: 'polar' }
    dom: dom
  }
  c = polyjs.chart spec

@examples.email_polarbars = (dom) ->
  data = polyjs.data {data: emails, meta: {id: {type: 'num'}, success: {type: 'cat'}}}
  spec = {
    layers: [
      {data: data, type: 'bar', x: 'bin(id,100)', y: 'success'}
    ]
    coord: {type: 'polar'}
    dom: dom
  }
  c = polyjs.chart spec
