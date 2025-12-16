if exists("b:current_syntax")
  finish
endif

syntax match todoH1 /^#\s.*$/
syntax match todoH2 /^##\s.*$/
syntax match todoH3 /^###\s.*$/

syntax match todoNew /\[ \]/
syntax match todoPending /\[-\]/
syntax match todoDone /\[x\]/

syntax match todoDoneLine /^\s*\[x\].*$/

syntax match todoPriorityHigh /!\+/
syntax match todoPriorityMed /\*\+/

syntax match todoDate /\d\{4\}-\d\{2\}-\d\{2\}/

syntax match todoTimestampNew /{new:[^}]\+}/ conceal
syntax match todoTimestampPending /{pending:[^}]\+}/ conceal
syntax match todoTimestampDone /{done:[^}]\+}/ conceal

syntax match todoTag /@\w\+/
syntax match todoContext /+\w\+/

syntax match todoComment /\/\/.*$/
syntax match todoNote /^\s*>.*$/

syntax match todoLink /https\?:\/\/[^ \t]*/

highlight default link todoH1 Title
highlight default link todoH2 Title
highlight default link todoH3 Title

highlight default todoNew ctermfg=Yellow guifg=#fabd2f
highlight default todoPending ctermfg=Blue guifg=#83a598
highlight default todoDone ctermfg=Green guifg=#b8bb26

highlight default todoDoneLine ctermfg=Gray guifg=#928374

highlight default todoTimestampNew ctermfg=Gray guifg=#928374
highlight default todoTimestampPending ctermfg=Gray guifg=#928374
highlight default todoTimestampDone ctermfg=Gray guifg=#928374

highlight default link todoPriorityHigh Error
highlight default link todoPriorityMed WarningMsg

highlight default link todoDate Number
highlight default link todoTag Keyword
highlight default link todoContext Type
highlight default link todoComment Comment
highlight default link todoNote Comment
highlight default link todoLink Underlined

let b:current_syntax = "todo"
