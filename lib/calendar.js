(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define('simple-calendar', ["jquery",
      "simple-module",
      "moment"], function ($, SimpleModule, moment) {
      return (root.returnExportsGlobal = factory($, SimpleModule, moment));
    });
  } else if (typeof exports === 'object') {
    // Node. Does not work with strict CommonJS, but
    // only CommonJS-like enviroments that support module.exports,
    // like Node.
    module.exports = factory(require("jquery"),
      require("simple-module"),
      require("moment"));
  } else {
    root.simple = root.simple || {};
    root.simple['calendar'] = factory(jQuery,
      SimpleModule,
      moment);
  }
}(this, function ($, SimpleModule, moment) {

var Calendar, calendar,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Calendar = (function(_super) {
  __extends(Calendar, _super);

  function Calendar() {
    return Calendar.__super__.constructor.apply(this, arguments);
  }

  Calendar.prototype.opts = {
    el: null,
    month: '',
    events: null,
    todos: null,
    eventHeight: 24,
    idKey: 'id'
  };

  Calendar.prototype._init = function() {
    this.el = $(this.opts.el);
    if (this.el.length < 1) {
      throw Error('simple calendar: el option is required');
    }
    this.month = moment(this.opts.month);
    if (!this.month.isValid()) {
      throw Error('simple calendar: month option is required');
    }
    this._render();
    this.events = [];
    this.todos = [];
    if (this.opts.events) {
      this.addEvent(this.opts.events);
    }
    if (this.opts.todos) {
      return this.addTodo(this.opts.todos);
    }
  };

  Calendar.prototype._render = function() {
    var $day, $days, $week, date, i, today, weekEnd, weekStart, _i, _j;
    this.el.addClass('simple-calendar');
    this.titleEl = $('<div class="week-title"></div>');
    this.weekdaysEl = $('<div class="weekdays"></div>').appendTo(this.titleEl);
    for (i = _i = 0; _i <= 6; i = ++_i) {
      $('<div class="weekday"></div>').text(moment().weekday(i).format('ddd')).appendTo(this.weekdaysEl);
    }
    this.weeksEl = $('<div class="weeks"></div>');
    today = moment().startOf('d');
    weekStart = this.month.clone().startOf('week');
    weekEnd = this.month.clone().endOf('week');
    while (this.month.isSame(weekStart, 'month') || this.month.isSame(weekEnd, 'month')) {
      $week = $("<div class=\"week\" data-week=\"" + (weekStart.format('YYYY-MM-DD')) + "\">\n  <div class=\"days\">\n  </div>\n  <div class=\"events\">\n  </div>\n</div>");
      $days = $week.find('.days');
      for (i = _j = 0; _j <= 6; i = ++_j) {
        date = weekStart.clone().weekday(i);
        $day = $("<div class=\"day\" data-date=\"" + (date.format('YYYY-MM-DD')) + "\">\n  <div class=\"info\">\n    <span class=\"desc\"></span>\n    <span class=\"num\">" + (date.date()) + "</span>\n  </div>\n  <div class=\"event-spacers\">\n  </div>\n  <div class=\"day-events\">\n  </div>\n  <div class=\"day-todos\">\n  </div>\n</div>").appendTo($days);
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
      }
      this.weeksEl.append($week);
      weekStart.add('1', 'w');
      weekEnd.add('1', 'w');
    }
    this.el.append(this.titleEl).append(this.weeksEl);
    return this._bind();
  };

  Calendar.prototype._bind = function() {
    this.el.on('click.calendar', '.day', (function(_this) {
      return function(e) {
        return _this.trigger('dayclick', [$(e.currentTarget)]);
      };
    })(this));
    this.el.on('click.calendar', '.event', (function(_this) {
      return function(e) {
        return _this.trigger('eventclick', [$(e.currentTarget)]);
      };
    })(this));
    this.el.on('mouseenter.calendar', '.event', (function(_this) {
      return function(e) {
        var $event, id;
        $event = $(e.currentTarget);
        id = $event.data(_this.opts.idKey);
        return _this.el.find(".event[data-" + _this.opts.idKey + "=" + id + "]").addClass('hover');
      };
    })(this));
    return this.el.on('mouseenter.calendar', '.event', (function(_this) {
      return function(e) {
        var $event, id;
        $event = $(e.currentTarget);
        id = $event.data(_this.opts.idKey);
        return _this.el.find(".event[data-" + _this.opts.idKey + "=" + id + "]").removeClass('hover');
      };
    })(this));
  };

  Calendar.prototype.addEvent = function(event) {
    return this.addEvents([event]);
  };

  Calendar.prototype.addEvents = function(events) {
    var event, _i, _len;
    for (_i = 0, _len = events.length; _i < _len; _i++) {
      event = events[_i];
      event.start = moment(event.start);
      event.end = moment(event.end);
      this.events.push(event);
    }
    this.events.sort(function(e1, e2) {
      return e1.start.diff(e2.start);
    });
    return this.renderEvents();
  };

  Calendar.prototype.renderEvents = function() {
    var event, _i, _len, _ref, _results;
    this.el.find(".week .events").empty();
    this.el.find(".day .event-spacers").empty();
    this.el.find(".day .day-events").empty();
    _ref = this.events;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      event = _ref[_i];
      if (event.end.diff(event.start, "d") > 0) {
        _results.push(this._renderEventAcrossDay(event));
      } else {
        _results.push(this._renderEventInDay(event));
      }
    }
    return _results;
  };

  Calendar.prototype._renderEventInDay = function(event) {
    var $day, $event, $events;
    $day = this.el.find(".day[data-date=" + (event.start.format('YYYY-MM-DD')) + "]");
    $events = $day.find('.day-events').show();
    $event = $("<div class=\"event\" data-id=\"" + event[this.opts.idKey] + "\">\n  <div class=\"event-wrapper\">\n    <p class=\"content\">" + event.content + "</p>\n  </div>\n</div>").appendTo($events);
    this.trigger('eventrender', [event, $event]);
    if ($.isFunction(this.opts.onEventRender)) {
      this.opts.onEventRender(event, $event);
    }
    return $event.data('event', event);
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
          if ($spacers.length > slot && $spacers.eq(slot).is("[data-" + this.opts.idKey + "]")) {
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
      $event = $("<div class=\"event\" data-id=\"" + event[this.opts.idKey] + "\">\n  <div class=\"event-wrapper\">\n    <p class=\"content\">" + event.content + "</p>\n  </div>\n</div>").css({
        width: days.length / 7 * 100 + '%',
        top: this.opts.eventHeight * slot,
        left: $week.find('.day').index(days[0]) / 7 * 100 + '%'
      }).data('event', event).appendTo($week.find('.events'));
      for (_k = 0, _len1 = days.length; _k < _len1; _k++) {
        $day = days[_k];
        $spacerList = $day.find('.event-spacers');
        $spacers = $spacerList.find('.event-spacer');
        if (slot < $spacers.length) {
          $spacers.eq(slot).attr("data-" + this.opts.idKey, event[this.opts.idKey]);
        } else {
          for (i = _l = 0, _ref = slot - $spacers.length; 0 <= _ref ? _l <= _ref : _l >= _ref; i = 0 <= _ref ? ++_l : --_l) {
            $spacer = $('<div class="event-spacer"></div>').appendTo($spacerList);
            $spacer.attr("data-" + this.opts.idKey, event[this.opts.idKey]);
          }
        }
      }
    }
    this.trigger('eventrender', [event, $event]);
    if ($.isFunction(this.opts.onEventRender)) {
      return this.opts.onEventRender(event, $event);
    }
  };

  return Calendar;

})(SimpleModule);

calendar = function(opts) {
  return new Calendar(opts);
};


return calendar;


}));

