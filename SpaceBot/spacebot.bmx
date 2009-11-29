
SuperStrict

Framework brl.blitz

Import "irc.bmx"

Import "Modules/debug.bmx"

Global SBConfig:IRCClientConfig = New IRCClientConfig
Global SBClient:IRCClient = New IRCClient

SBConfig.SetServer("irc.ajaxlife.net")
SBConfig.SetNick("SpaceBot")
SBConfig.SetName("SpaceBot")
SBConfig.SetIdent("spacebot")

SBClient.Connect(SBConfig)
SBClient.Send("JOIN #spacebot")

?threaded
	SBClient.BeginThread()
	
	Global terminate:Int = False
	
	While Not terminate
		If Input() = "" terminate = 1
	EndWhile
?Not threaded
	IRCClientThread(SBClient)
?
