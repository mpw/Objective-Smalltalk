sitebundle := STBundle bundleWithPath:'/Users/marcel/programming/Projects/WebSiteObjC/Sites/simple-dynamic.sited'.      
b := MPWFileBrowser new.      
r := sitebundle cachedResources.   
b browser setStore:r.      
b browser setRootReference:''.       

b view openInWindow:'Resources'.   

r  childrenOfReference:''            

r source at: (MPWGenericReference referenceWithPath:'' )     
r at:''   | contents ( )  

binding := b browser rootBinding.   

binding store  childrenOfReference: binding reference 

binding store 


MPWG

r childrenOfReference:''   
