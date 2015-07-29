$.fullCalendar.Grid.prototype.setElement = function(el) {
  var noEventClick = this.view.opt('noEventClick');
  var _this = this;

  this.el = el

  // attach a handler to the grid's root element.
  this.el.on('mousedown', function(ev) {
    if (
      (!$(ev.target).is('.fc-event-container *, .fc-more') || noEventClick) && // not an an event element, or "more.." link
      !$(ev.target).closest('.fc-popover').length // not on a popover (like the "more.." events one)
    ) {
      _this.dayMousedown(ev);
    }
  });

  // attach event-element-related handlers. in Grid.events
  // same garbage collection note as above.
  this.bindSegHandlers();

  this.bindGlobalHandlers();

}


var FC = $.fullCalendar;
var agendaSelectAcrossWeek
agendaSelectAcrossWeek = FC.views.agenda.class.extend({

  initialize: function() {
    FC.views.agenda.class.prototype.initialize.apply(this);
    this.timeGrid.renderSelection = this.renderSelection;
  },

  splitRange: function(range) {
    var start = range.start;
    var end = range.end;
    days = moment.duration(end.diff(start)).days()
    return _.map(_.range(days + 1), function(i) {
      day = moment(start).add(i, 'days');
      return {
        start: day.set({'hour': start.hour(), 'minute': start.minute()}),
        end: moment(day).set({'hour': end.hour(), 'minute': end.minute()})
      };
    })
  },

  reportSelection: function(range, ev) {
    _.each(this.splitRange(range), function(r) {
      FC.views.agenda.class.prototype.reportSelection.apply(this, [r, ev])
    }, this);
  },

  renderSelection: function(range) {
    var ranges = this.view.splitRange(range);
    if (this.view.opt('selectHelper')) {
      _.each(ranges, this.renderRangeHelper, this);
    }
    else {
      segs = _.reduce(ranges, function(s, r) {
        return s.concat(this.rangeToSegs(r))
      }, [], this);
      this.renderFill('highlight', segs);
      this.view.trigger('selectx', null, range.start, range.end, null);
    }
  }

});

$.fullCalendar.views.agendaSelectAcrossWeek = agendaSelectAcrossWeek;

