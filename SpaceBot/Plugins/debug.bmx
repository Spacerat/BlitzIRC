
Import joe.threadedio
Import "../irc.bmx"


AddHook(IRCClient.OUTHOOK, PrintIRCOutput, Null)
AddHook(IRCClient.INHOOK, PrintIRCInput, Null)

Function PrintIRCOutput:Object(id:Int, data:Object, context:Object)
	Local event:IRCEvent = IRCEvent(data)
	If Not event Return Null
	TPrint("OUTPUT: " + event.GetData())
	Return data
End Function

Function PrintIRCInput:Object(id:Int, data:Object, context:Object)
	Local event:IRCEvent = IRCEvent(data)
	If Not event Return Null
	TPrint("INPUT: " + event.GetData())
	Return data
End Function
