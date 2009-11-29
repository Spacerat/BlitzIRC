
SuperStrict

Import brl.threads
Import brl.socketstream
Import brl.textstream
Import brl.hook

Rem
bbdoc: IRC Event object
about: This object is passed to IRC hook functions in the same way TEvent is used by BRL.
EndRem
Type IRCEvent
	Field _hookid:Int
	Field _client:IRCClient
	Field _data:String
	
	Rem
	bbdoc: Create an IRC Event object
	about: id is the hook id. data is the message as a string.
	returns: The new IRCEvent
	EndRem
	Function Create:IRCEvent(id:Int, client:IRCClient, data:String)
		If Not client Throw "IRC Event must have a valid client"
		
		Local n:IRCEvent = New IRCEvent
		n._hookid = id
		n._client = client
		n._data = data
		
		Return n
	EndFunction
	
'#Region Get/Set methods

	Rem
	bbdoc: Get the message data
	EndRem
	Method GetData:String()
		Return _data
	End Method
'#End Region 
End Type

Rem
	bbdoc: IRC Configuration struct
	about: Stores information about a network and connection info for it.
EndRem
Type IRCClientConfig
	Field _Network:String
	Field _Port:Int = 6667
	Field _Nick:String
	Field _Name:String
	Field _Ident:String
	
'#Region Get/Set methods

	Rem
		bbdoc: Set the server and port
	EndRem
	Method SetServer(network:String, port:Int = 6667)
		_Network = network
		_Port = port
	End Method
	
	Rem
		bbdoc: Set the nick
	EndRem
	Method SetNick(nick:String)
		_Nick = nick
	End Method
	
	Rem
		bbdoc: Set the real name
	EndRem
	Method SetName(name:String)
		_Name = name
	End Method
	
	Rem
		bbdoc: Set the ident
	EndRem
	Method SetIdent(ident:String)
		_Ident = ident
	End Method
'#End Region 
	
End Type

Rem
	bbdoc: The main IRC client type
EndRem
Type IRCClient
	Global OUTHOOK:Int = AllocHookId()
	Global INHOOK:Int = AllocHookId()
	
	Field _socket:TSocket
	Field _stream:TSocketStream
	Field _utf8:TTextStream
	Field _running:Int = False
	
	Rem
		bbdoc: Connect to a server
	EndRem
	Method Connect:Int(config:IRCClientConfig)
		'Attempt a TCP connection
		_socket = TSocket.CreateTCP()
		_socket.Connect(HostIp(config._Network), config._Port)
		
		_stream = CreateSocketStream(_socket)
		_utf8 = TTextStream.Create(_stream, TTextStream.UTF8)
		
		Send("NICK " + config._Nick)
		Send("USER " + config._Nick + "8 * :" + config._Name)
		_running = True
	EndMethod
	
	Rem
		bbdoc: Start the thread
	EndRem
	Method BeginThread:TThread()
		?threaded
		Return TThread.Create(IRCClientThread, Self)
		?
		Throw "ERROR: Cannot create an IRC Client thread in non-threaded mode!"
	End Method
		
	Rem
		bbdoc: Send a string to the server
	EndRem
	Method Send(line:String, utf8:Int = True)
		RunIRCHookThread(IRCEvent.Create(OUTHOOK, Self, line))
		If utf8
			_utf8.WriteLine(line)
		Else
			_stream.WriteLine(line)
		EndIf
	End Method
	
	Rem
		bbdoc: Execute a client cycle.
	EndRem
	Method Run()
		While Not _stream.Eof()
			Local line:String = _stream.ReadLine()
			RunIRCHookThread(IRCEvent.Create(INHOOK, Self, line))
		Wend
	End Method

'#Region Get/Set/Is methods
	Method IsRunning:Int()
		Return _running
	End Method
'#End Region 

EndType

Rem
bbdoc: Run an IRC Event in a new thread.
returns: The new thread
EndRem
Function RunIRCHookThread:TThread(event:IRCEvent)
	?threaded
	Return TThread.Create(IRCHookThread, event)
	?Not threaded
	IRCHookThread(event)
	?
EndFunction

Function IRCClientThread:Object(data:Object)
	Local client:IRCClient = IRCClient(data)
	If Not client Return Null
	
	While client.IsRunning()
		client.Run()
	Wend
End Function

Function IRCHookThread:Object(data:Object)
	Local event:IRCEvent = IRCEvent(data)
	
	If (event)
		Return RunHooks(event._hookid, event)
	End If
End Function
