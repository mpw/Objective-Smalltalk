
extension NSApplication {

     -mainMenuTitle {
          self mainMenu itemArray firstObject title.
     }
     -appName {
           NSBundle mainBundle bundlePath lastPathComponent  stringByDeletingPathExtension.
     }
     -<void>setMenuAppName:newName  {
          var menuBar := self mainMenu.
          var appMenu := menuBar itemArray firstObject.
          var helpMenu := menuBar itemArray lastObject.
          var originalName := appMenu title.
          var appSubmenu := appMenu submenu.
          appMenu setTitle:newName.
          appSubmenu setTitle:newName.
          var items := appSubmenu itemArray.

          items firstObject setTitle:'About ', newName.
          (items at:(items count -2 ))  setTitle:'Quit ', newName.
     }
     -<void>changeTitleIfNecessary {
          var appName := self appName.
          appName ≠ self mainMenuTitle ifTrue: {
              self setMenuAppName:appName.
          }.
     }
}.

NSApplication sharedApplication changeTitleIfNecessary.

