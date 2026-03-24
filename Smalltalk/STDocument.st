context loadFramework: framework:AppKit.

extension STDocument {

  -compiler {
     NSApplication sharedApplication delegate compiler.
  }

  -<void>showWorkspace:sender {
      stdout println:'show workspace'.
      var scrollView.
      scrollView := NSScrollView alloc initWithFrame: (0@0 extent: 500@400) | autorelease.
      scrollView setAutoresizingMask: 18.
      scrollView setHasVerticalScroller: true.
      var workspace.
      workspace := STProgramTextView alloc initWithFrame: (0@0 extent: 500@400).
      workspace setAutoresizingMask: 18.
      scrollView setDocumentView:workspace.
      var windowController.
      windowController := scrollView openInWindowController:'Workspace'.
      self addWindowController:windowController.
      var window.
      window := windowController window.
      window setDelegate:self.
      workspace setCompiler: self compiler.
      workspace setDelegate: self.
      self workspaces addObject:workspace.
      stdout println:'STDocument did set up workspace'.
  }
  
 -<bool>turnIntoApp {
       var vm.
       fm := NSFileManager defaultManager.
       var appPath.
       appPath := NSBundle mainBundle bundlePath.
       var appPath.
       docPath := self fileURL path.
       var newAppPath.
       newAppPath := docPath stringByDeletingPathExtension stringByAppendingPathExtension:'app'.
       var resourcesPath.
       resourcesPath := newAppPath , '/Contents/Resources/finishLaunching/', docPath lastPathComponent.
       stdout println: resourcesPath.
       fm copyItemAtPath:appPath toPath:newAppPath error:nil.
       var text.
       text := self workspaces anyObject string .
       stdout println:text.
       var didWrite.
       didWrite := (text dataUsingEncoding:4) writeToFile:resourcesPath atomically:1.
       stdout println:didWrite.
  }


}
