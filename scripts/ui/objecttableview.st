#!env stui
#-<void>table:<ref>json
class Person {
   var first.
   var last.
   -description { 
      "<Person: {this:first} {this:last}> ".
   }
}.
j := #MPWJSONConverterStore{ mutable: true, converterClass: class:Person }  → scheme:file.
a ← j at:json.
stdline !  a.
table ← #MPWTableView{objects:(a)}.
app runFromCLI:(table inScrollView:(200@400 extent: 500@600)).
stdout do println: table objects each.
