
scheme TableStore : MPWMappingStore {
     var theList.
     var basePath.

     -renderFormOn: html {
        html form:{  
            html input:'' attributes:#{ type: 'text' , name: 'title' } .
        } attributes:#{ hx-post:'/tasks/newItem'    } .
      }          
      -renderTableOn: html { 
          html div: {
              html ! this:theList.
          } attributes: #{}.
      }          
      /item/:row/:columnName {  put {
          stdout println:'put at item in TableStore'.
          stdout println:"row: {row} column: {columnName}".
          newValue count > 0 ifTrue: {
               newValue ←newValue at: columnName.
          } ifFalse: {
               newValue ← false.
          }.
          newValue = 'on' ifTrue: {
                newValue ← true.
          }.
          var column ← this:theList columnForKey: columnName.
          stdout println: column.
          stdout println: newValue.
          column replaceObjectAtIndex: row intValue withObject: newValue.
          stdout println: 'did replace'.
          stdout println: this:theList.
          stdout println: 'returning to tasks'.
          ref:this:/tasks/items .
        }   get  { ref:this:/{this:basePath}/items .  } }

      /newItem {
                post {
                    stdout println:'post in the TableStore'.
                    this:theList insertObject: #Task{ title: ((newValue at:'title') ) } atIndex:0.
                    stdline ! ref:this:/ .
                    ref:this:/tasks/items .
                }
        }


                    

}.

