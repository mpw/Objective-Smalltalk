#!env st
#-<void>unique:<ref>t
words ← t value stringValue componentsSeparatedByCharactersInSet:NSCharacterSet whiteSpaceAndPunctuation.
lower ← words collect lowercaseString.
unique ← NSSet setWithArray:lower.
stdout do println: unique allObjects sorted each.
