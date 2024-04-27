#!env stui
#-taskstable
dl:tasks.dylib load


taskList ← #( #Task{ id:0, title: 'Submit paper', done: false }, #Task{ id:1, title: 'Write code', done: true } ).

stdout println:'hi'.
stdout println: taskList.

table :=  #MPWTableView{items: taskList }.
stdout println:table.
window ← #NSWindow{ frame:(600@300 extent:200@105),title:'Tasks', views:#[table]}.
stdout println:window.
app runFromCLI:window.

