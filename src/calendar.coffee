class Calendar extends SimpleModule

  opts:
    el: null # required
    month: '' # required, moment obj or date string
    timezone: null
    events: null
    todos: null
    eventHeight: 24
    eventKeys:
      id: 'id'
      start: 'start'
      end: 'end'
      content: 'content'
    todoKeys:
      id: 'id'
      start: 'start'
      end: 'end'
      completed: 'completed'
      content: 'content'
    allowDrag: true

  _tpl:
    layout: '''
      <div class="week-title">
        <div class="weekdays"></div>
      </div>
      <div class="weeks"></div>
    '''
    week: '''
      <div class="week">
        <div class="days"></div>
        <div class="events"></div>
      </div>
    '''
    day: '''
      <div class="day">
        <div class="info">
          <span class="num"></span>
        </div>
        <div class="event-spacers"></div>
        <div class="day-events"></div>
        <div class="day-todos"></div>
      </div>
    '''
    event: '''
      <div class="event">
        <div class="event-wrapper">
          <p class="content"></p>
        </div>
      </div>
    '''
    todo: '''
      <div class="todo">
        <div class="todo-wrapper">
          <input type="checkbox" class="cb-done" />
          <p class="content"></p>
        </div>
      </div>
    '''

  _init: ->
    @el = $(@opts.el)
    throw Error('simple calendar: el option is required') if @el.length < 1

    @month = @moment(@opts.month, 'YYYY-MM')
    throw Error('simple calendar: month option is required') unless @month.isValid()

    @_render()
    @events =
      inDay: []
      acrossDay: []
    @todos =
      inDay: []
      acrossDay: []

    if @opts.events
      @addEvent @opts.events

    if @opts.todos
      @addTodo @opts.todos

  _render: ->
    @el.empty()
      .addClass 'simple-calendar'
      .data 'calendar', @
    $(@_tpl.layout).appendTo(@el)
    @titleEl = @el.find('.week-title')
    @weekdaysEl = @el.find('.weekdays')
    for i in [0..6]
      $('<div class="weekday"></div>')
        .text(moment().weekday(i).format('ddd'))
        .appendTo(@weekdaysEl)

    @weeksEl = $('<div class="weeks"></div>')

    @el.append(@titleEl)
      .append(@weeksEl)

    @_renderGrid()
    @_bind()
    @_initDrag()


  _renderGrid: ->
    today = @moment().startOf('d')
    weekStart = @month.clone().startOf('week')
    weekEnd = @month.clone().endOf('week')

    while @month.isSame(weekStart, 'month') || @month.isSame(weekEnd, 'month')
      $week = $(@_tpl.week).attr
        'data-week': weekStart.format 'YYYY-MM-DD'
      $days = $week.find('.days')

      for i in [0..6]
        date = weekStart.clone().weekday(i)
        $day = $(@_tpl.day).attr
          'data-date': date.format 'YYYY-MM-DD'
        $day.find('.num').text date.date()
        $day.appendTo $days

        if date.isSame today
          $day.addClass('today')

        if date.isoWeekday() == 6
          $day.addClass 'sat'
        else if date.isoWeekday() == 7
          $day.addClass 'sun'

        unless date.isSame(@month, 'month')
          $day.addClass('other-month')

        @opts.onDayRender.call(@, date, $day) if $.isFunction(@opts.onDayRender)

      @weeksEl.append $week
      weekStart.add '1', 'w'
      weekEnd.add '1', 'w'

  _bind: ->
    @el.on 'click.calendar', '.day', (e) =>
      return if $(e.currentTarget).is '.dragover'
      @trigger 'dayclick', [$(e.currentTarget)]

    @el.on 'mousedown.calendar', '.day', (e) ->
      false

    @el.on 'click.calendar', '.event', (e) =>
      $event = $(e.currentTarget)
      event = $event.data 'event'
      @trigger 'eventclick', [event, $event]
      false

    @el.on 'click.calendar', '.todo', (e) =>
      $todo = $(e.currentTarget)
      todo = $todo.data 'todo'
      @trigger 'todoclick', [todo, $todo]
      false

    @el.on 'click.calendar', '.todo .cb-done', (e) =>
      e.stopPropagation()
      $cb = $(e.currentTarget)
      $todo = $cb.closest('.todo')
      todo = $todo.data 'todo'

      todo.completed = $cb.prop 'checked'
      $todo.toggleClass 'completed', todo.completed

      @trigger 'todocomplete', [todo, $todo]

    @el.on 'mouseenter.calendar', '.event', (e) =>
      $event = $(e.currentTarget)
      id = $event.data 'id'
      @el.find(".event[data-id=#{id}]").addClass('hover')

    @el.on 'mouseenter.calendar', '.event', (e) =>
      $event = $(e.currentTarget)
      id = $event.data 'id'
      @el.find(".event[data-id=#{id}]").removeClass('hover')

  _initDrag: ->
    return unless simple.dragdrop and @opts.allowDrag

    dragdrop = simple.dragdrop
      el: @el
      draggable: '.event'
      droppable: '.day'
      helper: ($event) ->
        $helper = $event.clone()
        event = $event.data 'event'
        days = event.end.clone().startOf('day').diff(event.start.clone().startOf('day'), 'd')
        if days > 0
          $helper.find('.content').text "(#{days + 1}天) #{event.content}"
          $helper.data 'cursorPosition', 'center'
        $helper.css
          'width': 'auto'
          'min-width': @el.find('.day').eq(0).width()
        .addClass 'drag-helper'
        return $helper
      placeholder: ($event) ->
        event = $event.data 'event'
        if event.acrossDay
          $events = @el.find(".event[data-id='#{event.id}']:not(.drag-helper)")
          $events.hide()
        null

    dragdrop.on 'dragenter', (e, event) =>
      $event = $(event.dragging)
      $target = $(event.target)

      event = $event.data 'event'
      return unless event

      days = event.end.clone().startOf('day').diff(event.start.clone().startOf('day'), 'd')

      @el.find('.day').removeClass 'dragover'
      index =  @el.find('.day').index($target)
      @el.find('.day').slice(index, days + index + 1).addClass 'dragover'

    dragdrop.on 'dragstart', (e, event) =>
      $event = $(event.dragging)
      event = $event.data 'event'
      return unless event

      $event.parents('.day').addClass('dragover')
      @el.find('.days').css('cursor', 'move');

    dragdrop.on 'dragend', (e, event) =>
      $event = $(event.dragging)
      event = $event.data 'event'
      return unless event

      if event.acrossDay
        $events = @el.find(".event[data-id='#{event.id}']:not(.drag-helper)")
        $events.show()
      setTimeout =>
        @el.find('.day').removeClass 'dragover'
      , 0
      @el.find('.days').css('cursor', 'default');

    dragdrop.on 'drop', (e, event) =>
      $event = $(event.dragging)
      $target = $(event.target)

      event = $event.data 'event'
      return unless event

      newDate = $target.data('date')
      differ = event.start.clone().startOf('day').diff(moment(newDate), 'd')
      return if differ is 0

      @el.find('.day').removeClass 'dragover'
      @el.find('.days').css('cursor', 'default');

      event.start.add(-differ, 'd')
      event.end.add(-differ, 'd')
      @replaceEvent(event)
      @trigger 'eventdrop', [event, differ]


  moment: (args...) ->
    if @opts.timezone
      moment.tz args..., @opts.timezone
    else
      moment args...

  findEvent: (eventId) ->
    for e in $.merge($.merge([], @events.inDay), @events.acrossDay)
      if e.id == eventId
        event = e
        break
    event

  _processEvent: (originEvent) ->
    return unless typeof originEvent == 'object'
    return originEvent if originEvent.origin

    event =
      id: originEvent[@opts.eventKeys.id]
      start: originEvent[@opts.eventKeys.start]
      end: originEvent[@opts.eventKeys.end]
      content: originEvent[@opts.eventKeys.content] || ''
      origin: originEvent

    event.start = @moment(event.start) unless moment.isMoment(event.start)
    event.end = @moment(event.end) unless moment.isMoment(event.end)

    if (@_DiffDay(event.end, event.start) != 0) or @isAllDayEvent(event)
      event.acrossDay = true

    event

  addEvent: (events) ->
    events = [events] unless $.isArray(events)
    eventsAcrossDay = []
    eventsInDay = []
    reorderList = []

    for event in events
      event = @_processEvent event

      continue unless @dateInMonth(event.start) or @dateInMonth(event.end) or (@month.isAfter(event.start, 'month') and @month.isBefore(event.end, 'month'))

      if event.acrossDay
        eventsAcrossDay.push event
      else
        eventsInDay.push event

    # render one day events
    if eventsInDay.length > 0
      $.merge @events.inDay, eventsInDay
      @events.inDay.sort (e1, e2) ->
        e1.start.diff e2.start

      @el.find( ".day .day-events" ).empty()
      for event in @events.inDay
        $event = @_renderEventInDay event
        $eventList = $event.parent()
        reorderList.push $eventList[0] if $.inArray($eventList[0], reorderList) < 0

    # render multi day events
    if eventsAcrossDay.length > 0
      $.merge @events.acrossDay, eventsAcrossDay
      @events.acrossDay.sort (e1, e2) ->
        result = e1.start.diff(e2.start, 'd')
        result = e2.end.diff(e1.start, 'd') - e1.end.diff(e2.start, 'd') if result == 0
        result = e1.start.diff(e2.start) if result ==0
        result = e1.end.diff(e2.end) if result == 0
        result = e1.content.length - e2.content.length if result == 0
        result

      @el.find('.event-spacers').empty()
      @el.find('.events').empty()
      for event in @events.acrossDay
        $event = @_renderAcrossDay event

  clearEvents: ->
    @events.inDay.length = 0
    @events.acrossDay.length = 0
    @el.find('.event-spacers').empty()
    @el.find('.events').empty()
    @el.find('.day-events').empty()

  removeEvent: (event) ->
    if typeof event == 'object'
      event = @_processEvent event
      eventId = event.id
    else
      eventId = event

    return unless event = @findEvent eventId

    if event.acrossDay
      @events.acrossDay.splice $.inArray(event, @events.acrossDay), 1
      @el.find('.event-spacers').empty()
      @el.find('.events').empty()
      @_renderAcrossDay e for e in @events.acrossDay
    else
      @events.inDay.splice $.inArray(event, @events.inDay), 1
      @el.find(".event[data-id=#{event.id}]").remove()

  replaceEvent: (newEvent) ->
    newEvent = @_processEvent newEvent
    return unless event = @findEvent newEvent.id

    $.extend event, newEvent

    if event.acrossDay
      @el.find('.event-spacers').empty()
      @el.find('.events').empty()
      @_renderAcrossDay e for e in @events.acrossDay
    else
      @_renderEventInDay event

  _renderEventInDay: (event) ->
    $day = @el.find ".day[data-date=#{event.start.format('YYYY-MM-DD')}]"
    $eventList = $day.find('.day-events')

    $event = @el.find(".event[data-id=#{event.id}]").remove()
    unless $event.length > 0
      $event = $(@_tpl.event).attr "data-id", event.id

    $event.data 'event', event
      .find('.content').text event.content
    $event.appendTo $eventList

    @trigger 'eventrender', [event, $event]
    @opts.onEventRender.call(@, event, $event) if $.isFunction(@opts.onEventRender)
    $event

  _DiffDay: (end, start)->
    end_day = end.clone().endOf('day')
    start_day = start.clone().endOf('day')
    return end_day.diff(start_day, 'days')

  _renderAcrossDay: (event, type = 'event') ->
    dayCount = @_DiffDay(event.end, event.start)
    rows = {}

    # calculate event across week
    for i in [0..dayCount]
      date = event.start.clone().add(i, 'd')
      $day = @el.find(".day[data-date=#{date.format('YYYY-MM-DD')}]")
      $week = $day.closest '.week'
      continue unless $week.length > 0

      week = $week.data 'week'
      rows[week] = [] unless rows[week]
      rows[week].push $day

    # calculate event position
    slot = {}
    for week, days of rows
      slot[week] = 0

      loop
        occupied = false
        for $day in days
          $spacers = $day.find '.event-spacer'
          if $spacers.length > slot[week] and $spacers.eq(slot[week]).is("[data-id]")
            occupied = true
            break

        if occupied
          slot[week] += 1
        else
          break

    events = []
    for week, days of rows
      $week = @el.find ".week[data-week=#{week}]"

      $event = if type is 'todo' then $(@_tpl.todo) else $(@_tpl.event)
      $event.attr("data-id", event.id).css
        width: days.length / 7 * 100 + '%'
        top: @opts.eventHeight * slot[week]
        left: $week.find('.day').index(days[0]) / 7 * 100 + '%'
      .data type, event

      $event.find('.content').text event.content
      $event.appendTo $week.find('.events')
      events.push $event[0]

      # render event placeholders
      for $day in days
        $spacerList = $day.find '.event-spacers'
        $spacers = $spacerList.find '.event-spacer'

        unless slot[week] < $spacers.length
          for i in [0..slot[week] - $spacers.length]
            $('<div class="event-spacer"></div>').appendTo($spacerList)
        $spacerList.find('.event-spacer').eq(slot[week]).attr("data-id", event.id)

    @trigger 'eventrender', [event, $(events)]
    @opts.onEventRender.call(@, event, $(events)) if $.isFunction(@opts.onEventRender)
    $(events)

  findTodo: (todoId) ->
    for t in @todos
      if t.id == todoId
        todo = t
        break
    todo

  _processTodo: (originTodo) ->
    return unless typeof originTodo == 'object'
    return originTodo if originTodo.origin

    todo =
      id: originTodo[@opts.todoKeys.id]
      start: originTodo[@opts.todoKeys.start]
      end: originTodo[@opts.todoKeys.end]
      completed: originTodo[@opts.todoKeys.completed]
      content: originTodo[@opts.todoKeys.content]
      origin: originTodo

    todo.start = @moment(todo.start) if todo.start and !moment.isMoment(todo.start)
    todo.end = @moment(todo.end) unless moment.isMoment(todo.end)
    todo.acrossDay = true if todo.start and (@_DiffDay(todo.end, todo.start) != 0)

    todo

  addTodo: (todos) ->
    todos = [todos] unless $.isArray todos
    todosAcrossDay = []
    todosInDay = []
    reorderList = []

    for todo in todos
      todo = @_processTodo todo
      continue unless @dateInMonth(todo.end)

      if todo.acrossDay
        todosAcrossDay.push todo
      else
        todosInDay.push todo

    # render one day todos
    if todosInDay.length > 0
      $.merge @todos.inDay, todosInDay
      @todos.inDay.sort (t1, t2) ->
        t1.end.diff t2.end

      @el.find(".day .day-todos").empty()
      for todo in @todos.inDay
        $todo = @_renderTodoInDay todo
        $todoList = $todo.parent()
        reorderList.push $todoList[0] if $.inArray($todoList[0], reorderList) < 0

    # render multi day events
    if todosAcrossDay.length > 0
      $.merge @todos.acrossDay, todosAcrossDay
      @todos.acrossDay.sort (e1, e2) ->
        result = e1.start.diff(e2.start, 'd')
        result = e2.end.diff(e1.start, 'd') - e1.end.diff(e2.start, 'd') if result == 0
        result = e1.start.diff(e2.start) if result ==0
        result = e1.end.diff(e2.end) if result == 0
        result = e1.content.length - e2.content.length if result == 0
        result

      @el.find('.events .todo').remove()
      for todo in @todos.acrossDay
        $todo = @_renderAcrossDay todo, 'todo'

  removeTodo: (todo) ->
    if typeof todo == 'object'
      todo = @_processTodo todo
      todoId = todo.id
    else
      todoId = todo

    return unless todo = @findTodo todoId
    @todos.splice $.inArray(todo, @todos), 1
    @el.find(".todo[data-id=#{todo.id}]").remove()

  replaceTodo: (newTodo) ->
    newTodo = @_processTodo newTodo
    return unless todo = @findTodo newTodo.id
    $.extend todo, newTodo
    @_renderTodoInDay todo

  clearTodos: ->
    @todos.inDay.length = 0
    @todos.acrossDay.length = 0
    @el.find('.todo').remove()

  _renderTodoInDay: (todo) ->
    $todoList = @el.find(".day[data-date=#{todo.end.format('YYYY-MM-DD')}] .day-todos")
    $todo = @el.find(".todo[data-id=#{todo.id}]").remove()

    unless $todo.length > 0
      $todo = $(@_tpl.todo).attr "data-id", todo.id

    $todo.data 'todo', todo
      .toggleClass 'completed', todo.completed
    $todo.find('.content').text todo.content
    $todo.find('.cb-done').prop('checked', todo.completed)
    $todoList.append($todo)

    @trigger 'todorender', [todo, $todo]
    @opts.onTodoRender.call(@, todo, $todo) if $.isFunction(@opts.onTodoRender)
    $todo

  setMonth: (month) ->
    @month = @moment(month, 'YYYY-MM')
    throw Error('simple calendar: month param should be YYYY-MM') unless @month.isValid()

    @clearEvents()
    @clearTodos()
    @weeksEl.empty()
    @_renderGrid()

  dateInMonth: (date) ->
    $day = @el.find(".day[data-date=#{date.format 'YYYY-MM-DD'}]")
    $day.length > 0

  isAllDayEvent: (event) ->
    dayStart = event.start.clone().startOf('day')
    dayEnd = event.end.clone().endOf('day')
    dayStart.isSame(event.start) and dayEnd.isSame(event.end, 'm')

  destroy: ->
    @clearEvents()
    @clearTodos()
    @el.off '.calendar'
      .removeData 'calendar'
      .removeClass 'simple-calendar'
      .empty()


calendar = (opts) ->
  new Calendar(opts)
