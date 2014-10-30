
class Calendar extends SimpleModule

  opts:
    el: null # required
    month: '' # required, moment obj or date string
    events: null
    todos: null
    eventHeight: 24
    idKey: 'id'

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
    @titleEl = $('<div class="week-title"></div>')
    @weekdaysEl = $('<div class="weekdays"></div>').appendTo(@titleEl)
    for i in [0..6]
      $('<div class="weekday"></div>')
        .text(moment().weekday(i).format('ddd'))
        .appendTo(@weekdaysEl)

    @weeksEl = $('<div class="weeks"></div>')

    today = moment().startOf('d')
    weekStart = @month.clone().startOf('week')
    weekEnd = @month.clone().endOf('week')

    while @month.isSame(weekStart, 'month') || @month.isSame(weekEnd, 'month')
      $week = $("""
        <div class="week" data-week="#{weekStart.format('YYYY-MM-DD')}">
          <div class="days">
          </div>
          <div class="events">
          </div>
        </div>
      """)
      $days = $week.find('.days')

      for i in [0..6]
        date = weekStart.clone().weekday(i)
        $day = $("""
          <div class="day" data-date="#{date.format('YYYY-MM-DD')}">
            <div class="info">
              <span class="desc"></span>
              <span class="num">#{date.date()}</span>
            </div>
            <div class="event-spacers">
            </div>
            <div class="day-events">
            </div>
            <div class="day-todos">
            </div>
          </div>
        """).appendTo($days)

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
      @trigger 'eventclick', [$(e.currentTarget)]

    @el.on 'mouseenter.calendar', '.event', (e) =>
      $event = $(e.currentTarget)
      id = $event.data @opts.idKey
      @el.find(".event[data-#{@opts.idKey}=#{id}]").addClass('hover')

    @el.on 'mouseenter.calendar', '.event', (e) =>
      $event = $(e.currentTarget)
      id = $event.data @opts.idKey
      @el.find(".event[data-#{@opts.idKey}=#{id}]").removeClass('hover')

  addEvent: (event) ->
    @addEvents [event]

  addEvents: (events) ->
    for event in events
      event.start = moment event.start
      event.end = moment event.end
      @events.push event

    @events.sort (e1, e2) ->
      e1.start.diff e2.start

    @renderEvents()

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

    $event = $("""
      <div class="event" data-id="#{event[@opts.idKey]}">
        <div class="event-wrapper">
          <p class="content">#{event.content}</p>
        </div>
      </div>
    """).appendTo($events)

    @trigger 'eventrender', [event, $event]
    @opts.onEventRender(event, $event) if $.isFunction(@opts.onEventRender)
    $event.data 'event', event

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
      $event = $("""
        <div class="event" data-id="#{event[@opts.idKey]}">
          <div class="event-wrapper">
            <p class="content">#{event.content}</p>
          </div>
        </div>
      """).css
        width: days.length / 7 * 100 + '%'
        top: @opts.eventHeight * slot
        left: $week.find('.day').index(days[0]) / 7 * 100 + '%'
      .data 'event', event
      .appendTo($week.find('.events'))

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
    @opts.onEventRender(event, $event) if $.isFunction(@opts.onEventRender)


calendar = (opts) ->
  new Calendar(opts)
