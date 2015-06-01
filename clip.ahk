;^c::
#Persistent
return

OnClipboardChange:
  ClipWait  
  StringReplace, clipboard, clipboard, C:\dev\src\, \, All
  clipboard = %clipboard%
return