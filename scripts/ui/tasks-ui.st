#!env stui
#-taskstable
framework:Sails load

class Task : STEntity  {
   var title.
   var done.
}


taskList ← #( #Task{ id:0, title: 'Submit paper', done: false }, #Task{ id:1, title: 'Write code', done: true } ).

stdout println:'hi'.
stdout println: taskList.

table ← #MPWTableView{items: taskList  }.

table inScrollView:(200@400 extent: 500@600).
