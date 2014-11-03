
class Calendar extends SimpleModule

  opts:
    el: null # required
    month: '' # required, moment obj or date string
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
      due: 'due'
      completed: 'completed'
      content: 'content'

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
          <span class="desc"></span>
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
          <span class="content"></span>
        </div>
      </div>
    '''

  _init: ->
    @el = $(@opts.el)
    throw Error('simple calendar: el option is required') if @el.length < 1

    @month = moment(@opts.month, 'YYYY-MM')
    throw Error('simple calendar: month option is required') unless @month.isValid()

    @_render()
    @events = 
      inDay: []
      acrossDay: []
    @todos = []

    if @opts.events
      @addEvent @opts.events

    if @opts.todos
      @addTodo @opts.todos

  _render: ->
    @el.addClass 'simple-calendar'
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

  _renderGrid: ->
    today = moment().startOf('d')
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
            .find('.desc')
            .text(@_t 'today')

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
      @trigger 'dayclick', [$(e.currentTarget)]

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

  findEvent: (eventId) ->
    for e in $.merge([], @events.inDay, @events.acrossDay)
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
      content: originEvent[@opts.eventKeys.content]
      origin: originEvent

    event.start = moment(event.start) unless moment.isMoment(event.start)
    event.end = moment(event.end) unless moment.isMoment(event.end)
    event.acrossDay = event.end.diff(event.start, "d") > 0
    event

  addEvent: (events) ->
    events = [events] unless $.isArray(events)
    eventsAcrossDay = []
    eventsInDay = []
    reorderList = []

    for event in events
      event = @_processEvent event
      if event.acrossDay
        eventsAcrossDay.push event
      else
        eventsInDay.push event

    # render one day events
    if eventsInDay.length > 0
      $.merge @events.inDay, eventsInDay
      @events.inDay.sort (e1, e2) ->
        e1.start.diff e2.start

      $event = @_renderEventInDay event for event in eventsInDay
      $eventList = $event.parent()
      reorderList.push $eventList[0] if $.inArray($eventList[0], reorderList) < 0

    # resort event list if neccesary
    for list in reorderList
      $events = $(list).children('.event')
      $events.sort (el1, el2) ->
        event1 = $(el1).data 'event'
        event2 = $(el2).data 'event'
        event1.start.diff event2.start
      $events.detach().appendTo list

    # render multi day events
    if eventsAcrossDay.length > 0
      $.merge @events.acrossDay, eventsAcrossDay
      @events.acrossDay.sort (e1, e2) ->
        e1.start.diff e2.start

      @el.find( ".week .events" ).empty()
      @_renderEventAcrossDay event for event in @events.acrossDay

  clearEvents: ->
    @events.inDay.length = 0
    @events.acrossDay.length = 0
    @el.find( ".day .event-spacers" ).empty()
    @el.find( ".day .day-events" ).empty()
    @el.find( ".week .events" ).empty()

  removeEvent: (event) ->
    if typeof event == 'object'
      event = @_processEvent event
      eventId = event.id
    else
      eventId = event

    return unless event = @findEvent eventId

    if event.acrossDay
      @events.acrossDay.splice $.inArray(event, @events.acrossDay), 1
      @el.find( ".day .event-spacers" ).empty()
      @el.find( ".week .events" ).empty()
      @_renderEventAcrossDay e for e in @events.acrossDay
    else
      @events.inDay.splice $.inArray(event, @events.inDay), 1
      @el.find(".event[data-id=#{event.id}]").remove()

  replaceEvent: (newEvent) ->
    newEvent = @_processEvent newEvent
    return unless event = @findEvent newEvent.id

    $.extend event, newEvent

    if event.acrossDay
      @el.find( ".day .event-spacers" ).empty()
      @el.find( ".week .events" ).empty()
      @_renderEventAcrossDay e for e in @events.acrossDay
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

  _renderEventAcrossDay: (event) ->
    dayCount = event.end.diff(event.start, 'd')
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
    slot = 0
    loop
      occupied = false

      for week, days of rows
        for $day in days
          $spacers = $day.find '.event-spacer'
          if $spacers.length > slot and $spacers.eq(slot).is("[data-id]")
            occupied = true
            break
        break if occupied
      break unless occupied
      slot += 1

    events = []
    for week, days of rows
      $week = @el.find ".week[data-week=#{week}]"

      $event = $(@_tpl.event).attr "data-id", event.id
      .css
        width: days.length / 7 * 100 + '%'
        top: @opts.eventHeight * slot
        left: $week.find('.day').index(days[0]) / 7 * 100 + '%'
      .data 'event', event

      $event.find('.content').text event.content
      $event.appendTo $week.find('.events')
      events.push $event[0]

      # render event placeholders
      for $day in days
        $spacerList = $day.find '.event-spacers'
        $spacers = $spacerList.find '.event-spacer'

        if slot < $spacers.length
          $spacers.eq(slot).attr("data-id", event.id)
        else
          for i in [0..slot - $spacers.length]
            $spacer = $('<div class="event-spacer"></div>').appendTo($spacerList)
            $spacer.attr("data-id", event.id)

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
      due: originTodo[@opts.todoKeys.due]
      completed: originTodo[@opts.todoKeys.completed]
      content: originTodo[@opts.todoKeys.content]
      origin: originTodo

    todo.due = moment(todo.due) unless moment.isMoment(todo.due)
    todo

  addTodo: (todos) ->
    todos = [todos] unless $.isArray todos
    reorderList = []

    for todo in todos
      todo = @_processTodo todo
      @todos.push todo
      $todo = @_renderTodo todo
      $todoList = $todo.parent()
      reorderList.push $todoList[0] if $.inArray($todoList[0], reorderList) < 0

    @todos.sort (t1, t2) ->
      t1.due.diff t2.due

    # resort todo list if neccesary
    for list in reorderList
      $todos = $(list).children('.todo')
      $todo.sort (el1, el2) ->
        todo1 = $(el1).data 'todo'
        todo2 = $(el2).data 'todo'
        todo1.due.diff todo2.due
      $todos.detach().appendTo list

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
    @_renderTodo todo

  clearTodos: ->
    @todos.length = 0
    @el.find( ".day .day-todos" ).empty()

  _renderTodo: (todo)->
    $todoList = @el.find(".day[data-date=#{todo.due.format('YYYY-MM-DD')}] .day-todos")
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
    @month = moment(month, 'YYYY-MM')
    throw Error('simple calendar: month param should be YYYY-MM') unless @month.isValid()

    @clearEvents()
    @clearTodos()
    @weeksEl.empty()
    @_renderGrid()

  destroy: ->
    @clearEvents()
    @clearTodos()
    @el.off '.calendar'
      .removeData 'calendar'
      .removeClass 'simple-calendar'
      .empty()


calendar = (opts) ->
  new Calendar(opts)
