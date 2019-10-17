context loadFramework: framework:AppKit.

extension STDocument {

  -compiler {
     NSApplication sharedApplication delegate compiler.
  }

  -<void>showWorkspace:sender {
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


}
