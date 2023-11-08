context loadFramework: framework:AppKit.

extension STDocument {

  -compiler {
     NSApplication sharedApplication delegate compiler.
  }

  -<void>showWorkspace:sender {
      stdout println:'show workspace'.
      scrollView := NSScrollView alloc initWithFrame: (0@0 extent: 500@400) | autorelease.
      scrollView setAutoresizingMask: 18.
      scrollView setHasVerticalScroller: true.
      workspace := MPWProgramTextView alloc initWithFrame: (0@0 extent: 500@400).
      workspace setAutoresizingMask: 18.
      scrollView setDocumentView:workspace.
      windowController := scrollView openInWindowController:'Workspace'.
      self addWindowController:windowController.
      window := windowController window.
      window setDelegate:self.
      workspace setCompiler: self compiler.
      workspace setDelegate: self.
      self workspaces addObject:workspace.
      stdout println:'did set up workspace'.
  }
 -<bool>turnIntoApp {
       fm := NSFileManager defaultManager.
       appPath := NSBundle mainBundle bundlePath.
      docPath := self fileURL path.
       newAppPath := docPath stringByDeletingPathExtension stringByAppendingPathExtension:'app'.
       resourcesPath := newAppPath , '/Contents/Resources/finishLaunching/', docPath lastPathComponent.
       stdout println: resourcesPath.
       fm copyItemAtPath:appPath toPath:newAppPath error:nil.
       text := self workspaces anyObject string .
       stdout println:text.
       didWrite := (text dataUsingEncoding:4) writeToFile:resourcesPath atomically:1.
       stdout println:didWrite.
  }


}
