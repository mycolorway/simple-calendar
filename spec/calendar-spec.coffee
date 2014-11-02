
describe 'Simple Calendar', ->
  calendar = null
  $('<div id="calendar"></div>').appendTo('body')

  beforeEach ->
    calendar = simple.calendar
      month: '2014-10'
      el: '#calendar'
      events: [{
        id: 1,
        start: '2014-10-10T14:20:00',
        end: '2014-10-13T14:20:00',
        content: 'event 1'
      }, {
        id: 2,
        start: '2014-10-11T14:20:00',
        end: '2014-10-12T14:20:00',
        content: 'event 2'
      }, {
        id: 3,
        start: '2014-10-10T14:20:00',
        end: '2014-10-10T16:20:00',
        content: 'event 3'
      }]
      todos: [{
        id: 1,
        completed: false,
        content: 'todo 1',
        due: '2014-10-28T14:20:00'
      }, {
        id: 2,
        completed: true,
        content: 'todo 2',
        due: '2014-10-28T14:20:00'
      }]

  afterEach ->
    calendar.destroy()

  it 'should render calendar grid', ->
    expect(calendar.el.hasClass('simple-calendar')).toBe(true)
    expect(calendar.el.find('.day:not(.other-month)').length).toBe(31)
    expect(calendar.el.find('.day:first').data('date')).toBe('2014-09-29')
    expect(calendar.el.find('.day:last').data('date')).toBe('2014-11-02')


  # event specs

  it 'should render events', ->
    expect(calendar.el.find('.event:contains(event 1)').length).toBeGreaterThan(0)
    expect(calendar.el.find('.event:contains(event 2)').length).toBeGreaterThan(0)
    expect(calendar.el.find('.event:contains(event 3)').length).toBeGreaterThan(0)

  it 'should remove event from dom after removing it', ->
    calendar.addEvent
      id: 4
      start: '2014-10-10T15:20:00'
      end: '2014-10-10T17:20:00'
      content: 'event 4'

    expect(calendar.el.find('.event:contains(event 4)').length).toBeGreaterThan(0)

    calendar.removeEvent 4

    expect(calendar.el.find('.event:contains(event 4)').length).toBe(0)

  it 'should rerender event after replacing it', ->
    calendar.replaceEvent
      id: 3
      start: '2014-10-05T14:20:00'
      end: '2014-10-05T16:20:00'
      content: 'modified event 3'

    $event = calendar.el.find('.event[data-id=3]')
    expect($event.find('.content').text()).toBe('modified event 3')
    expect($event.closest('.day').is('[data-date=2014-10-05]')).toBe(true)

  it 'should remove all events after calling clearEvents', ->
    calendar.clearEvents()
    expect(calendar.events.inDay.length).toBe(0)
    expect(calendar.events.acrossDay.length).toBe(0)
    expect(calendar.el.find('.event').length).toBe(0)
    expect(calendar.el.find('.event-spacer').length).toBe(0)


  # todo specs

  it 'should render todos after adding them', ->
    expect(calendar.el.find('.todo:contains(todo 1)').length).toBe(1)
    expect(calendar.el.find('.todo:contains(todo 2)').length).toBe(1)

  it 'should remove todo from dom after removing it', ->
    calendar.addTodo
      id: 3
      completed: false
      content: 'todo 3'
      due: '2014-10-29T14:20:00'

    expect(calendar.el.find('.todo:contains(todo 3)').length).toBeGreaterThan(0)

    calendar.removeTodo 3

    expect(calendar.el.find('.todo:contains(todo 3)').length).toBe(0)

  it 'should rerender todo after replacing it', ->
    calendar.replaceTodo
      id: 2
      completed: false
      due: '2014-10-29T14:20:00'
      content: 'modified todo 2'

    $todo = calendar.el.find('.todo[data-id=2]')
    expect($todo.find('.content').text()).toBe('modified todo 2')
    expect($todo.closest('.day').is('[data-date=2014-10-29]')).toBe(true)

  it 'should remove all todos after calling clearTodos', ->
    calendar.clearTodos()
    expect(calendar.todos.length).toBe(0)
    expect(calendar.el.find('.todo').length).toBe(0)


  it 'should rerender calendar grid and clear all events/todos after setting a new month', ->
    calendar.setMonth '2014-12'

    expect(calendar.month.isSame(moment '2014-12', 'YYYY-MM')).toBe(true)
    expect(calendar.el.find('.day:first').data('date')).toBe('2014-12-01')
    expect(calendar.el.find('.day:last').data('date')).toBe('2015-01-04')

    expect(calendar.events.inDay.length).toBe(0)
    expect(calendar.events.acrossDay.length).toBe(0)
    expect(calendar.el.find('.event').length).toBe(0)
    expect(calendar.el.find('.event-spacer').length).toBe(0)

    expect(calendar.todos.length).toBe(0)
    expect(calendar.el.find('.todo').length).toBe(0)

  it 'should trigger custom event', ->
    calendar.addEvent
      id: 1
      start: '2014-10-10T14:20:00'
      end: '2014-10-13T14:20:00'
      content: 'event 1'

    calendar.addTodo
      id: 1
      completed: false
      content: 'todo 1'
      due: '2014-10-28T14:20:00'

    dayClickCallback = jasmine.createSpy 'dayClickCallback'
    eventClickCallback = jasmine.createSpy 'eventClickCallback'
    todoClickCallback = jasmine.createSpy 'todoClickCallback'
    todoCompleteCallback = jasmine.createSpy 'todoCompleteCallback'

    calendar.on 'dayclick', (e, $day) ->
      dayClickCallback($day[0])
    calendar.on 'eventclick', (e, event, $event) ->
      eventClickCallback($event[0])
    calendar.on 'todoclick', (e, todo, $todo) ->
      todoClickCallback($todo[0])
    calendar.on 'todocomplete', (e, todo, $todo) ->
      todoCompleteCallback($todo[0])

    expect(dayClickCallback).not.toHaveBeenCalled()
    expect(eventClickCallback).not.toHaveBeenCalled()
    expect(todoClickCallback).not.toHaveBeenCalled()
    expect(todoCompleteCallback).not.toHaveBeenCalled()

    $day = calendar.el.find('.day:first').click()
    $event = calendar.el.find('.event:first').click()
    $todo = calendar.el.find('.todo:first').click()
    $todo.find('.cb-done').click()

    expect(dayClickCallback).toHaveBeenCalledWith($day[0])
    expect(eventClickCallback).toHaveBeenCalledWith($event[0])
    expect(todoClickCallback).toHaveBeenCalledWith($todo[0])
    expect(todoCompleteCallback).toHaveBeenCalledWith($todo[0])

