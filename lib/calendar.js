(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define('simple-calendar', ["jquery",
      "simple-module",
      "moment-timezone"], function ($, SimpleModule, moment) {
      return (root.returnExportsGlobal = factory($, SimpleModule, moment));
    });
  } else if (typeof exports === 'object') {
    // Node. Does not work with strict CommonJS, but
    // only CommonJS-like enviroments that support module.exports,
    // like Node.
    module.exports = factory(require("jquery"),
      require("simple-module"),
      require("moment-timezone"));
  } else {
    root.simple = root.simple || {};
    root.simple['calendar'] = factory(jQuery,
      SimpleModule,
      moment);
  }
}(this, function ($, SimpleModule, moment) {

var Calendar, calendar,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

Calendar = (function(_super) {
  __extends(Calendar, _super);

  function Calendar() {
    return Calendar.__super__.constructor.apply(this, arguments);
  }

  Calendar.prototype.opts = {
    el: null,
    month: '',
    timezone: null,
    events: null,
    todos: null,
    eventHeight: 22,
    eventKeys: {
      id: 'id',
      start: 'start',
      end: 'end',
      content: 'content'
    },
    todoKeys: {
      id: 'id',
      due: 'due',
      completed: 'completed',
      content: 'content'
    }
  };

  Calendar.prototype._tpl = {
    layout: '<div class="week-title">\n  <div class="weekdays"></div>\n</div>\n<div class="weeks"></div>',
    week: '<div class="week">\n  <div class="days"></div>\n  <div class="events"></div>\n</div>',
    day: '<div class="day">\n  <div class="info">\n    <span class="desc"></span>\n    <span class="num"></span>\n  </div>\n  <div class="event-spacers"></div>\n  <div class="day-events"></div>\n  <div class="day-todos"></div>\n</div>',
    event: '<div class="event">\n  <div class="event-wrapper">\n    <p class="content"></p>\n  </div>\n</div>',
    todo: '<div class="todo">\n  <div class="todo-wrapper">\n    <input type="checkbox" class="cb-done" />\n    <span class="content"></span>\n  </div>\n</div>'
  };

  Calendar.prototype._init = function() {
    this.el = $(this.opts.el);
    if (this.el.length < 1) {
      throw Error('simple calendar: el option is required');
    }
    this.month = this.moment(this.opts.month, 'YYYY-MM');
    if (!this.month.isValid()) {
      throw Error('simple calendar: month option is required');
    }
    this._render();
    this.events = {
      inDay: [],
      acrossDay: []
    };
    this.todos = [];
    if (this.opts.events) {
      this.addEvent(this.opts.events);
    }
    if (this.opts.todos) {
      return this.addTodo(this.opts.todos);
    }
  };

  Calendar.prototype._render = function() {
    var i, _i;
    this.el.empty().addClass('simple-calendar').data('calendar', this);
    $(this._tpl.layout).appendTo(this.el);
    this.titleEl = this.el.find('.week-title');
    this.weekdaysEl = this.el.find('.weekdays');
    for (i = _i = 0; _i <= 6; i = ++_i) {
      $('<div class="weekday"></div>').text(moment().weekday(i).format('ddd')).appendTo(this.weekdaysEl);
    }
    this.weeksEl = $('<div class="weeks"></div>');
    this.el.append(this.titleEl).append(this.weeksEl);
    this._renderGrid();
    return this._bind();
  };

  Calendar.prototype._renderGrid = function() {
    var $day, $days, $week, date, i, today, weekEnd, weekStart, _i, _results;
    today = this.moment().startOf('d');
    weekStart = this.month.clone().startOf('week');
    weekEnd = this.month.clone().endOf('week');
    _results = [];
    while (this.month.isSame(weekStart, 'month') || this.month.isSame(weekEnd, 'month')) {
      $week = $(this._tpl.week).attr({
        'data-week': weekStart.format('YYYY-MM-DD')
      });
      $days = $week.find('.days');
      for (i = _i = 0; _i <= 6; i = ++_i) {
        date = weekStart.clone().weekday(i);
        $day = $(this._tpl.day).attr({
          'data-date': date.format('YYYY-MM-DD')
        });
        $day.find('.num').text(date.date());
        $day.appendTo($days);
        if (date.isSame(today)) {
          $day.addClass('today').find('.desc').text(this._t('today'));
        }
        if (date.isoWeekday() === 6) {
          $day.addClass('sat');
        } else if (date.isoWeekday() === 7) {
          $day.addClass('sun');
        }
        if (!date.isSame(this.month, 'month')) {
          $day.addClass('other-month');
        }
        if ($.isFunction(this.opts.onDayRender)) {
          this.opts.onDayRender.call(this, date, $day);
        }
      }
      this.weeksEl.append($week);
      weekStart.add('1', 'w');
      _results.push(weekEnd.add('1', 'w'));
    }
    return _results;
  };

  Calendar.prototype._bind = function() {
    this.el.on('click.calendar', '.day', (function(_this) {
      return function(e) {
        return _this.trigger('dayclick', [$(e.currentTarget)]);
      };
    })(this));
    this.el.on('mousedown.calendar', '.day', function(e) {
      return false;
    });
    this.el.on('click.calendar', '.event', (function(_this) {
      return function(e) {
        var $event, event;
        $event = $(e.currentTarget);
        event = $event.data('event');
        _this.trigger('eventclick', [event, $event]);
        return false;
      };
    })(this));
    this.el.on('click.calendar', '.todo', (function(_this) {
      return function(e) {
        var $todo, todo;
        $todo = $(e.currentTarget);
        todo = $todo.data('todo');
        _this.trigger('todoclick', [todo, $todo]);
        return false;
      };
    })(this));
    this.el.on('click.calendar', '.todo .cb-done', (function(_this) {
      return function(e) {
        var $cb, $todo, todo;
        e.stopPropagation();
        $cb = $(e.currentTarget);
        $todo = $cb.closest('.todo');
        todo = $todo.data('todo');
        todo.completed = $cb.prop('checked');
        $todo.toggleClass('completed', todo.completed);
        return _this.trigger('todocomplete', [todo, $todo]);
      };
    })(this));
    this.el.on('mouseenter.calendar', '.event', (function(_this) {
      return function(e) {
        var $event, id;
        $event = $(e.currentTarget);
        id = $event.data('id');
        return _this.el.find(".event[data-id=" + id + "]").addClass('hover');
      };
    })(this));
    return this.el.on('mouseenter.calendar', '.event', (function(_this) {
      return function(e) {
        var $event, id;
        $event = $(e.currentTarget);
        id = $event.data('id');
        return _this.el.find(".event[data-id=" + id + "]").removeClass('hover');
      };
    })(this));
  };

  Calendar.prototype.moment = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (this.opts.timezone) {
      return moment.tz.apply(moment, __slice.call(args).concat([this.opts.timezone]));
    } else {
      return moment.apply(null, args);
    }
  };

  Calendar.prototype.findEvent = function(eventId) {
    var e, event, _i, _len, _ref;
    _ref = $.merge($.merge([], this.events.inDay), this.events.acrossDay);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      if (e.id === eventId) {
        event = e;
        break;
      }
    }
    return event;
  };

  Calendar.prototype._processEvent = function(originEvent) {
    var event;
    if (typeof originEvent !== 'object') {
      return;
    }
    if (originEvent.origin) {
      return originEvent;
    }
    event = {
      id: originEvent[this.opts.eventKeys.id],
      start: originEvent[this.opts.eventKeys.start],
      end: originEvent[this.opts.eventKeys.end],
      content: originEvent[this.opts.eventKeys.content] || '',
      origin: originEvent
    };
    if (!moment.isMoment(event.start)) {
      event.start = this.moment(event.start);
    }
    if (!moment.isMoment(event.end)) {
      event.end = this.moment(event.end);
    }
    if (event.end.diff(event.start, "d") > 0 || this.isAllDayEvent(event)) {
      event.acrossDay = true;
    }
    return event;
  };

  Calendar.prototype.addEvent = function(events) {
    var $event, $eventList, event, eventsAcrossDay, eventsInDay, reorderList, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
    if (!$.isArray(events)) {
      events = [events];
    }
    eventsAcrossDay = [];
    eventsInDay = [];
    reorderList = [];
    for (_i = 0, _len = events.length; _i < _len; _i++) {
      event = events[_i];
      event = this._processEvent(event);
      if (!(this.dateInMonth(event.start) || this.dateInMonth(event.end))) {
        continue;
      }
      if (event.acrossDay) {
        eventsAcrossDay.push(event);
      } else {
        eventsInDay.push(event);
      }
    }
    if (eventsInDay.length > 0) {
      $.merge(this.events.inDay, eventsInDay);
      this.events.inDay.sort(function(e1, e2) {
        return e1.start.diff(e2.start);
      });
      this.el.find(".day .day-events").empty();
      _ref = this.events.inDay;
      for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
        event = _ref[_j];
        $event = this._renderEventInDay(event);
        $eventList = $event.parent();
        if ($.inArray($eventList[0], reorderList) < 0) {
          reorderList.push($eventList[0]);
        }
      }
    }
    if (eventsAcrossDay.length > 0) {
      $.merge(this.events.acrossDay, eventsAcrossDay);
      this.events.acrossDay.sort(function(e1, e2) {
        var result;
        result = e1.start.diff(e2.start, 'd');
        if (result === 0) {
          result = e2.end.diff(e1.start, 'd') - e1.end.diff(e2.start, 'd');
        }
        if (result === 0) {
          result = e1.start.diff(e2.start);
        }
        if (result === 0) {
          result = e1.end.diff(e2.end);
        }
        if (result === 0) {
          result = e1.content.length - e2.content.length;
        }
        return result;
      });
      this.el.find(".day .event-spacers").empty();
      this.el.find(".week .events").empty();
      _ref1 = this.events.acrossDay;
      for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
        event = _ref1[_k];
        $event = this._renderEventAcrossDay(event);
      }
    }
    return events;
  };

  Calendar.prototype.clearEvents = function() {
    this.events.inDay.length = 0;
    this.events.acrossDay.length = 0;
    this.el.find(".day .event-spacers").empty();
    this.el.find(".day .day-events").empty();
    return this.el.find(".week .events").empty();
  };

  Calendar.prototype.removeEvent = function(event) {
    var e, eventId, _i, _len, _ref, _results;
    if (typeof event === 'object') {
      event = this._processEvent(event);
      eventId = event.id;
    } else {
      eventId = event;
    }
    if (!(event = this.findEvent(eventId))) {
      return;
    }
    if (event.acrossDay) {
      this.events.acrossDay.splice($.inArray(event, this.events.acrossDay), 1);
      this.el.find(".day .event-spacers").empty();
      this.el.find(".week .events").empty();
      _ref = this.events.acrossDay;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        e = _ref[_i];
        _results.push(this._renderEventAcrossDay(e));
      }
      return _results;
    } else {
      this.events.inDay.splice($.inArray(event, this.events.inDay), 1);
      return this.el.find(".event[data-id=" + event.id + "]").remove();
    }
  };

  Calendar.prototype.replaceEvent = function(newEvent) {
    var e, event, _i, _len, _ref, _results;
    newEvent = this._processEvent(newEvent);
    if (!(event = this.findEvent(newEvent.id))) {
      return;
    }
    $.extend(event, newEvent);
    if (event.acrossDay) {
      this.el.find(".day .event-spacers").empty();
      this.el.find(".week .events").empty();
      _ref = this.events.acrossDay;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        e = _ref[_i];
        _results.push(this._renderEventAcrossDay(e));
      }
      return _results;
    } else {
      return this._renderEventInDay(event);
    }
  };

  Calendar.prototype._renderEventInDay = function(event) {
    var $day, $event, $eventList;
    $day = this.el.find(".day[data-date=" + (event.start.format('YYYY-MM-DD')) + "]");
    $eventList = $day.find('.day-events');
    $event = this.el.find(".event[data-id=" + event.id + "]").remove();
    if (!($event.length > 0)) {
      $event = $(this._tpl.event).attr("data-id", event.id);
    }
    $event.data('event', event).find('.content').text(event.content);
    $event.appendTo($eventList);
    this.trigger('eventrender', [event, $event]);
    if ($.isFunction(this.opts.onEventRender)) {
      this.opts.onEventRender.call(this, event, $event);
    }
    return $event;
  };

  Calendar.prototype._renderEventAcrossDay = function(event) {
    var $day, $event, $spacer, $spacerList, $spacers, $week, date, dayCount, days, events, i, occupied, rows, slot, week, _i, _j, _k, _l, _len, _len1, _ref;
    dayCount = event.end.diff(event.start, 'd');
    rows = {};
    for (i = _i = 0; 0 <= dayCount ? _i <= dayCount : _i >= dayCount; i = 0 <= dayCount ? ++_i : --_i) {
      date = event.start.clone().add(i, 'd');
      $day = this.el.find(".day[data-date=" + (date.format('YYYY-MM-DD')) + "]");
      $week = $day.closest('.week');
      if (!($week.length > 0)) {
        continue;
      }
      week = $week.data('week');
      if (!rows[week]) {
        rows[week] = [];
      }
      rows[week].push($day);
    }
    slot = 0;
    while (true) {
      occupied = false;
      for (week in rows) {
        days = rows[week];
        for (_j = 0, _len = days.length; _j < _len; _j++) {
          $day = days[_j];
          $spacers = $day.find('.event-spacer');
          if ($spacers.length > slot && $spacers.eq(slot).is("[data-id]")) {
            occupied = true;
            break;
          }
        }
        if (occupied) {
          break;
        }
      }
      if (!occupied) {
        break;
      }
      slot += 1;
    }
    events = [];
    for (week in rows) {
      days = rows[week];
      $week = this.el.find(".week[data-week=" + week + "]");
      $event = $(this._tpl.event).attr("data-id", event.id).css({
        width: days.length / 7 * 100 + '%',
        top: this.opts.eventHeight * slot,
        left: $week.find('.day').index(days[0]) / 7 * 100 + '%'
      }).data('event', event);
      $event.find('.content').text(event.content);
      $event.appendTo($week.find('.events'));
      events.push($event[0]);
      for (_k = 0, _len1 = days.length; _k < _len1; _k++) {
        $day = days[_k];
        $spacerList = $day.find('.event-spacers');
        $spacers = $spacerList.find('.event-spacer');
        if (slot < $spacers.length) {
          $spacers.eq(slot).attr("data-id", event.id);
        } else {
          for (i = _l = 0, _ref = slot - $spacers.length; 0 <= _ref ? _l <= _ref : _l >= _ref; i = 0 <= _ref ? ++_l : --_l) {
            $spacer = $('<div class="event-spacer"></div>').appendTo($spacerList);
            $spacer.attr("data-id", event.id);
          }
        }
      }
    }
    this.trigger('eventrender', [event, $(events)]);
    if ($.isFunction(this.opts.onEventRender)) {
      this.opts.onEventRender.call(this, event, $(events));
    }
    return $(events);
  };

  Calendar.prototype.findTodo = function(todoId) {
    var t, todo, _i, _len, _ref;
    _ref = this.todos;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      t = _ref[_i];
      if (t.id === todoId) {
        todo = t;
        break;
      }
    }
    return todo;
  };

  Calendar.prototype._processTodo = function(originTodo) {
    var todo;
    if (typeof originTodo !== 'object') {
      return;
    }
    if (originTodo.origin) {
      return originTodo;
    }
    todo = {
      id: originTodo[this.opts.todoKeys.id],
      due: originTodo[this.opts.todoKeys.due],
      completed: originTodo[this.opts.todoKeys.completed],
      content: originTodo[this.opts.todoKeys.content],
      origin: originTodo
    };
    if (!moment.isMoment(todo.due)) {
      todo.due = this.moment(todo.due);
    }
    return todo;
  };

  Calendar.prototype.addTodo = function(todos) {
    var $todo, $todoList, $todos, list, reorderList, todo, _i, _j, _len, _len1, _results;
    if (!$.isArray(todos)) {
      todos = [todos];
    }
    reorderList = [];
    for (_i = 0, _len = todos.length; _i < _len; _i++) {
      todo = todos[_i];
      todo = this._processTodo(todo);
      if (!this.dateInMonth(todo.due)) {
        continue;
      }
      this.todos.push(todo);
      $todo = this._renderTodo(todo);
      $todoList = $todo.parent();
      if ($.inArray($todoList[0], reorderList) < 0) {
        reorderList.push($todoList[0]);
      }
    }
    this.todos.sort(function(t1, t2) {
      return t1.due.diff(t2.due);
    });
    _results = [];
    for (_j = 0, _len1 = reorderList.length; _j < _len1; _j++) {
      list = reorderList[_j];
      $todos = $(list).children('.todo');
      $todo.sort(function(el1, el2) {
        var todo1, todo2;
        todo1 = $(el1).data('todo');
        todo2 = $(el2).data('todo');
        return todo1.due.diff(todo2.due);
      });
      _results.push($todos.detach().appendTo(list));
    }
    return _results;
  };

  Calendar.prototype.removeTodo = function(todo) {
    var todoId;
    if (typeof todo === 'object') {
      todo = this._processTodo(todo);
      todoId = todo.id;
    } else {
      todoId = todo;
    }
    if (!(todo = this.findTodo(todoId))) {
      return;
    }
    this.todos.splice($.inArray(todo, this.todos), 1);
    return this.el.find(".todo[data-id=" + todo.id + "]").remove();
  };

  Calendar.prototype.replaceTodo = function(newTodo) {
    var todo;
    newTodo = this._processTodo(newTodo);
    if (!(todo = this.findTodo(newTodo.id))) {
      return;
    }
    $.extend(todo, newTodo);
    return this._renderTodo(todo);
  };

  Calendar.prototype.clearTodos = function() {
    this.todos.length = 0;
    return this.el.find(".day .day-todos").empty();
  };

  Calendar.prototype._renderTodo = function(todo) {
    var $todo, $todoList;
    $todoList = this.el.find(".day[data-date=" + (todo.due.format('YYYY-MM-DD')) + "] .day-todos");
    $todo = this.el.find(".todo[data-id=" + todo.id + "]").remove();
    if (!($todo.length > 0)) {
      $todo = $(this._tpl.todo).attr("data-id", todo.id);
    }
    $todo.data('todo', todo).toggleClass('completed', todo.completed);
    $todo.find('.content').text(todo.content);
    $todo.find('.cb-done').prop('checked', todo.completed);
    $todoList.append($todo);
    this.trigger('todorender', [todo, $todo]);
    if ($.isFunction(this.opts.onTodoRender)) {
      this.opts.onTodoRender.call(this, todo, $todo);
    }
    return $todo;
  };

  Calendar.prototype.setMonth = function(month) {
    this.month = this.moment(month, 'YYYY-MM');
    if (!this.month.isValid()) {
      throw Error('simple calendar: month param should be YYYY-MM');
    }
    this.clearEvents();
    this.clearTodos();
    this.weeksEl.empty();
    return this._renderGrid();
  };

  Calendar.prototype.dateInMonth = function(date) {
    var $day;
    $day = this.el.find(".day[data-date=" + (date.format('YYYY-MM-DD')) + "]");
    return $day.length > 0;
  };

  Calendar.prototype.isAllDayEvent = function(event) {
    var dayEnd, dayStart;
    dayStart = event.start.clone().startOf('day');
    dayEnd = event.end.clone().endOf('day');
    return dayStart.isSame(event.start) && dayEnd.isSame(event.end, 'm');
  };

  Calendar.prototype.destroy = function() {
    this.clearEvents();
    this.clearTodos();
    return this.el.off('.calendar').removeData('calendar').removeClass('simple-calendar').empty();
  };

  return Calendar;

})(SimpleModule);

calendar = function(opts) {
  return new Calendar(opts);
};


return calendar;


}));

