#!env stui
#-text

class Controller {
   -<void>textEntered:sender {
       stdout println: sender stringValue.
   }
}
text ← #NSTextField{ frame:(180@24) }.
controller ← #Controller{} .

text → port:controller/textEntered: .
