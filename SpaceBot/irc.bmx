
SuperStrict

Import brl.threads
Import brl.socketstream
Import brl.textstream
Import brl.hook

Type IRCEvent
	Field _hookid:Int
	Field _client:IRCClient
	Field _data:String
	
	Function Create:IRCEvent(id:Int, client:IRCClient, data:String)
		If Not client Throw "IRC Event must have a valid client"
		
		Local n:IRCEvent = New IRCEvent
		n._hookid = id
		n._client = client
		n._data = data
		
		Return n
	EndFunction
	
	Method GetData:String()
		Return _data
	End Method
End Type

Rem
	bbdoc: IRC Configuration struct
EndRem
Type IRCClientConfig
	Field _Network:String
	Field _Port:Int = 6667
	Field _Nick:String
	Field _Name:String
	Field _Ident:String
	
	Method SetServer(network:String, port:Int = 6667)
		_Network = network
		_Port = port
	End Method
	
	Method SetNick(nick:String)
		_Nick = nick
	End Method
	
	Method SetName(name:String)
		_Name = name
	End Method
	
	Method SetIdent(ident:String)
		_Ident = ident
	End Method
	
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
		
	Method Send(line:String, utf8:Int = True)
		RunIRCHookThread(IRCEvent.Create(OUTHOOK, Self, line))
		If utf8
			_utf8.WriteLine(line)
		Else
			_stream.WriteLine(line)
		EndIf
	End Method
	
	Method Run()
		While Not _stream.Eof()
			Local line:String = _stream.ReadLine()
			RunIRCHookThread(IRCEvent.Create(INHOOK, Self, line))
		Wend
	End Method

'#Region Getter/Setter methods
	Method IsRunning:Int()
		Return _running
	End Method
'#End Region 

EndType

Function IRCClientThread:Object(data:Object)
	Local client:IRCClient = IRCClient(data)
	If Not client Return Null
	
	While client.IsRunning()
		client.Run()
	Wend
End Function

Function RunIRCHookThread:TThread(event:IRCEvent)
	?threaded
	Return TThread.Create(IRCHookThread, event)
	?Not threaded
	IRCHookThread(event)
	?
EndFunction

Function IRCHookThread:Object(data:Object)
	Local event:IRCEvent = IRCEvent(data)
	
	If (event)
		Return RunHooks(event._hookid, event)
	End If
End Function
