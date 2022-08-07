#!env st
#-<void>parse:<ref>xmlIn
parser := MPWMAXParser parser.
parser setStreamingThreshhold:1.
parser setUndefinedTagAction:1.
source := xmlIn source.
target := ref:file:/tmp/rows.plist writeStream.
parser → target.
source → parser.
parser parse: xmlIn value.
#source run.
target close.
