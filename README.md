Simple Calendar
=============

团队协作工具[Tower](http://tower.im)使用的日历组件，依赖：

- JQuery 2.0+
- [Simple Module](https://github.com/mycolorway/simple-module)
- [Moment.js](http://momentjs.com/)

### 使用方法

在页面里引用相关脚本和样：

```html
<link media="all" rel="stylesheet" type="text/css" href="path/to/calendar.css" />
<script type="text/javascript" src="path/to/jquery.min.js"></script>
<script type="text/javascript" src="path/to/module.js"></script>
<script type="text/javascript" src="path/to/moment.js"></script>
<script type="text/javascript" src="path/to/calendar.js"></script>
```

初始化calendar对象：

```
var calendar = simple.calendar({
  el: '#calendar',
  month: '2014-11',
  events: [...]
});

```

### API 文档

####初始化选项

__el__ selector/jquery object/dom element

初始化日历的容器元素，必选

__month__ string: YYYY-MM

指定日历应该渲染哪个月的日历，必选

__events__ array

被渲染的日历事件数据

__todos__ array

被渲染的日历任务数据

__eventKeys__ object

日历事件的数据结构映射，默认值是：
```js
{
  id: 'id', // 事件的id
  start: 'start', // 事件开始时间
  end: 'end', // 事件结束时间
  content: 'content' // 事件内容
}
```
组件会按照会按照这个key值映射重构传入的数据，原始数据会被保存在origin对象中。

__todoKeys__ object

日历任务的数据结构映射，默认值是：
```js
{
  id: 'id', // 任务的id
  due: 'due', // 任务的截止时间
  completed: 'completed', // 任务的完成状态
  content: 'content' // 任务的内容
}
```
组件会按照会按照这个key值映射重构传入的数据，原始数据会被保存在origin对象中。

__eventHeight__ number

日历渲染事件的高度，默认值是22，这个值需要跟CSS里的高度设置一致。


#### 方法

__findEvent(eventId)__

查找eventId对应的event数据，返回event object

__addEvent(events)__

添加新的日历事件，接受对象或数组

__clearEvents()__

清除所有的日历事件

__removeEvent(event)__

清除指定的日历事件，接受event object或者eventId

__replaceEvent(newEvent)__

用新的event数据替换老的event数据，通过eventId来匹配

__findTodo(todoId)__

查找todoId对应的任务数据，返回todo object

__addTodo(todos)__

添加新的日历任务，接受对象或数组

__clearTodos()__

清除所有的日历任务

__removeTodo(todo)__

清除指定的日历任务，接受todo object或者todoId

__replaceTodo(newTodo)__

用新的todo数据替换老的todo数据，通过todoId来匹配

__setMonth(month)__

重新设置渲染的月份，接受的字符串格式为：YYYY-MM，同时会清除所有的事件和任务

__dateInMonth(date)__

判断某个日期是不是在当前渲染的月历里面，接受moment对象，返回Boolean值

__isAllDayEvent(event)__

判断某个事件是否是全天事件（开始时间和结束时间分别在某一天的开始和结束），返回Boolean值

__destroy()__

销毁calendar对象，恢复初始化前的状态


#### 自定义事件

__eventrender(event, $event)__

渲染事件的时候触发，传入event数据和对应的dom元素作为参数

__todorender(todo, $todo)__

渲染任务的时候触发，传入todo数据和对应的dom元素作为参数

__dayclick($day)__

点击日历上的某一天时触发，传入对应的dom元素作为参数

__eventclick(event, $event)__

点击日历上的事件时触发，传入对应事件的数据和dom元素作为参数

__todoclick(todo, $todo)__

点击日历上的任务时触发，传入对应任务的数据和dom元素作为参数
