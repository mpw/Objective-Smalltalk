class Hello
{
   -main:args
   {
        var store.
        scheme:db := class:MPWDictStore store.
        db:hello := 'Hello World'.
        db:hi :=  'hi there, world'.
        store := scheme:db.
        store serveOn:9001.
        class:NSRunLoop currentRunLoop run.
        0.
   }
}
