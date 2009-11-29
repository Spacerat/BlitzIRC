
SuperStrict

Framework brl.blitz

Import "irc.bmx"

Import "Modules/debug.bmx"
Import "Modules/ping.bmx"

Global SBConfig:IRCClientConfig = New IRCClientConfig
Global SBClient:IRCClient = New IRCClient

?Threaded
Print "THREADING ENABLED"
?

SBConfig.SetServer("irc.ajaxlife.net")
SBConfig.SetNick("SpaceBot")
SBConfig.SetName("SpaceBot")
SBConfig.SetIdent("spacebot")

SBClient.Connect(SBConfig)


?threaded
	SBClient.BeginThread()
	
	Global terminate:Int = False
	
	While Not terminate
		SBClient.Send(TInput(">"))
	EndWhile
?Not threaded
	IRCClientThread(SBClient)
?
