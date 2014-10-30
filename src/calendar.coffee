
class Calendar extends SimpleModule

  opts:
    el: null # required
    month: '' # required, moment obj or date string
    events: null
    todos: null
    eventHeight: 24
    idKey: 'id'

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

    @month = moment(@opts.month)
    throw Error('simple calendar: month option is required') unless @month.isValid()

    @_render()
    @events = []
    @todos = []

    if @opts.events
      @addEvent @opts.events

    if @opts.todos
      @addTodo @opts.todos

  _render: ->
    @el.addClass('simple-calendar')
    $(@_tpl.layout).appendTo(@el)
    @titleEl = @el.find('.week-title')
    @weekdaysEl = @el.find('.weekdays')
    for i in [0..6]
      $('<div class="weekday"></div>')
        .text(moment().weekday(i).format('ddd'))
        .appendTo(@weekdaysEl)

    @weeksEl = $('<div class="weeks"></div>')

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

    @el.append(@titleEl)
      .append(@weeksEl)

    @_bind()

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
      id = $event.data @opts.idKey
      @el.find(".event[data-#{@opts.idKey}=#{id}]").addClass('hover')

    @el.on 'mouseenter.calendar', '.event', (e) =>
      $event = $(e.currentTarget)
      id = $event.data @opts.idKey
      @el.find(".event[data-#{@opts.idKey}=#{id}]").removeClass('hover')

  addEvent: (events) ->
    events = [events] unless $.isArray(events)
    for event in events
      event.start = moment event.start
      event.end = moment event.end
      @events.push event

    @events.sort (e1, e2) ->
      e1.start.diff e2.start

    @renderEvents()

  clearEvents: ->
    @events.length = 0

  renderEvents: ->
    @el.find( ".week .events" ).empty()
    @el.find( ".day .event-spacers" ).empty()
    @el.find( ".day .day-events" ).empty()

    for event in @events
      if event.end.diff(event.start, "d") > 0
        @_renderEventAcrossDay event
      else
        @_renderEventInDay event

  _renderEventInDay: (event) ->
    $day = @el.find ".day[data-date=#{event.start.format('YYYY-MM-DD')}]"
    $events = $day.find('.day-events').show()

    $event = $(@_tpl.event).attr "data-#{@opts.idKey}", event[@opts.idKey]
      .data 'event', event
    $event.find('.content').text event.content
    $event.appendTo $events

    @trigger 'eventrender', [event, $event]
    @opts.onEventRender.call(@, event, $event) if $.isFunction(@opts.onEventRender)

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
          if $spacers.length > slot and $spacers.eq(slot).is("[data-#{@opts.idKey}]")
            occupied = true
            break
        break if occupied
      break unless occupied
      slot += 1

    events = []
    for week, days of rows
      $week = @el.find ".week[data-week=#{week}]"

      $event = $(@_tpl.event).attr "data-#{@opts.idKey}", event[@opts.idKey]
      .css
        width: days.length / 7 * 100 + '%'
        top: @opts.eventHeight * slot
        left: $week.find('.day').index(days[0]) / 7 * 100 + '%'
      .data 'event', event

      $event.find('.content').text event.content
      $event.appendTo $week.find('.events')

      # render event placeholders
      for $day in days
        $spacerList = $day.find '.event-spacers'
        $spacers = $spacerList.find '.event-spacer'

        if slot < $spacers.length
          $spacers.eq(slot).attr("data-#{@opts.idKey}", event[@opts.idKey])
        else
          for i in [0..slot - $spacers.length]
            $spacer = $('<div class="event-spacer"></div>').appendTo($spacerList)
            $spacer.attr("data-#{@opts.idKey}", event[@opts.idKey])

    @trigger 'eventrender', [event, $event]
    @opts.onEventRender.call(@, event, $event) if $.isFunction(@opts.onEventRender)

  addTodo: (todos) ->
    todos = [todos] unless $.isArray todos

    for todo in todos
      todo.due = moment todo.due
      @todos.push todo

    @todos.sort (t1, t2) ->
      t1.due.diff t2.due

    @renderTodos()

  clearTodos: ->
    @todos.length = 0

  renderTodos: ->
    @el.find( ".day .day-todos" ).empty()

    for todo in @todos
      $todoList = @el.find(".day[data-date=#{todo.due.format('YYYY-MM-DD')}] .day-todos")
      $todo = $(@_tpl.todo).attr "data-#{@opts.idKey}", todo[@opts.idKey]
        .data 'todo', todo
      $todo.find('.content').text todo.content
      $todoList.append($todo).show()

      if todo.completed
        $todo.addClass('completed')
        $todo.find('.cb-done').prop('checked', todo.completed)

      @trigger 'todorender', [todo, $todo]
      @opts.onTodoRender.call(@, todo, $todo) if $.isFunction(@opts.onTodoRender)


calendar = (opts) ->
  new Calendar(opts)
