 extension NSDictionary { 
  -at:ref {  self objectForKey:ref stringValue. }
  -at:ref put:value { value ifNotNil:{ self setObject:value forKey:ref stringValue. }. }
  -deleteAt:ref { self removeObjectForKey:ref stringValue. }
  -evaluateIdentifier:id withContext:c {  self at:id. } 
}

shell runInteractiveLoop.
