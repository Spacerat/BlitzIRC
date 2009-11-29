SuperStrict

Import "../irc.bmx"

AddHook(IRCClient.INHOOK, IRCPingPong, Null)

Function IRCPingPong:Object(id:Int, data:Object, context:Object)
	Local event:IRCEvent = IRCEvent(data)
	If Not event Return Null
	
	If event.GetCommand() = "PING"
		event.GetClient().Send("PONG :"+event._hostmask)
	End If
	
End Function
