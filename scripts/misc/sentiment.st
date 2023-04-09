#!env stsh
#-sentiment:text
(ref:http://text-processing.com/api/sentiment/ postForm: #{ #text: text }) 
