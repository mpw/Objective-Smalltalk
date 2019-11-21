
extension NSApplication {

     -mainMenuTitle {
          self mainMenu itemArray firstObject title.
     }
     -appName {
           NSBundle mainBundle bundlePath lastPathComponent  stringByDeletingPathExtension.
     }
     -<void>setMenuAppName:newName  {
          menuBar := self mainMenu.
          appMenu := menuBar itemArray firstObject.
          helpMenu := menuBar itemArray lastObject.
          originalName := appMenu title.
          appSubmenu := appMenu submenu.
          appMenu setTitle:newName.
          appSubmenu setTitle:newName.
          items := appSubmenu itemArray.

          items firstObject setTitle:'About ', newName.
          (items at:(items count -2 ))  setTitle:'Quit ', newName.
     }
     -<void>changeTitleIfNecessary {
          appName := self appName.
          appName ≠ self mainMenuTitle ifTrue: {
              self setMenuAppName:appName.
          }.
     }
}.

NSApplication sharedApplication changeTitleIfNecessary.

