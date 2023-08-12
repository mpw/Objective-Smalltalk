class Hello
{
   -main:args
   {
        var dict.
        var store.
        store := class:MPWDictStore store.
        scheme:db := store.
        db:hello := 'World'.
        store serveOnPort:9001 intValue.
        class:NSRunLoop currentRunLoop run.
        0.
   }
}
