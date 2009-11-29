
SuperStrict

Import brl.threads
Import brl.socketstream
Import brl.textstream
Import brl.hook
Import brl.linkedlist

Rem
bbdoc: IRC Event object
about: This object is passed to IRC hook functions in the same way TEvent is used by BRL.
EndRem
Type IRCEvent
	Field _client:IRCClient
	Field _data:String
	Field _hookid:Int
	
	Field _hostmask:String
	Field _user:String
	Field _host:String
	Field _command:String
	Field _params:String[]
	Field _message:String
	
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
		
		n.SetData(data)
		
		Return n
	EndFunction
	
	Rem
	bbdoc: Sets the data associated with this message
	about: Also parses the data and splits its different parts. 
	EndRem
	Method SetData(data:String)
		Local parts:String[]
		Local cindex:Int = 0
		Local params:TList = New TList
		_data = data
		parts = _data.Split(" ")

		If _data[0] = Asc(":")
			cindex = 1
			parts = _data[1..].Split(" ")
			_hostmask = parts[0].Split("!")[0]
			If parts[0].Split("!").Dimensions()[0] > 1
				_user = parts[0].Split("!")[1].Split("@")[0]
				_host = parts[0].Split("!")[1].Split("@")[1]
			EndIf
		End If
		
		_command = parts[cindex]
		If _data.Find(" :") > 0 Then
			_message = _data.Split(" :")[1]
			parts = _data.Split(" :")[0].Split(" ")
		EndIf
		
		
		Local paramcount:Int = 0
		For Local i:Int = cindex + 1 To parts.Dimensions()[0] - 1
			If parts[i][0] = Asc(":") Exit
			paramcount:+1
		Next
		
		_params = New String[paramcount]
		
		For Local i:Int = cindex + 1 To parts.Dimensions()[0] - 1
			_params[i - cindex - 1] = parts[i]
		Next
		
	EndMethod
	
'#Region Get/Set methods

	Rem
	bbdoc: Get the full message string
	EndRem
	Method GetData:String()
		Return _data
	End Method
	
	Rem
	bbdoc: Get the IRC client object
	EndRem	
	Method GetClient:IRCClient()
		Return _client
	End Method
	
	Rem
	bbdoc: Get the command string
	EndRem
	Method GetCommand:String()
		Return _command
	End Method
	
	Rem
	bbdoc: Get an array of parameters
	EndRem
	Method GetParams:String[] ()
		Return _params
	End Method
	
	Rem
	bbdoc: Get the servername/nickname
	EndRem
	Method GetNickname:String()
		Return _hostmask
	End Method
	
	Rem
	bbdoc: Get the host address
	EndRem
	Method GetHost:String()
		Return _host
	End Method
	
	Rem
	bbdoc: Get the message/trailing parameter
	EndRem
	Method GetMessage:String()
		Return _message
	EndMethod
	
	Rem
	bbdoc: Get the user/ident
	EndRem
	Method GetUser:String()
		Return _user
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

	Field _config:IRCClientConfig
	Field _nick:String
	
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
		Send("USER " + config._Nick + " " + config._Ident + " 8* :" + config._Name)
		_running = True
		
		_config = config
		_nick = _config._Nick
		
	EndMethod
	
	Rem
		bbdoc: Start the thread
	EndRem
	?threaded
	Method BeginThread:TThread()	
		Return TThread.Create(IRCClientThread, Self)
	End Method
	?Not threaded
	Method BeginThread:Object()
		Return Null
	End Method
	?
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
	
	Method GetConfig:IRCClientConfig()
		Return _config
	End Method
	
	Method GetNick:String()
		Return _nick
	End Method
	
	Method GetIdent:String()
		Return _config._Ident
	End Method
'#End Region 

EndType

Rem
bbdoc: Run an IRC Event in a new thread.
returns: The new thread in threaded mode, otherwise returns the IRC hook data.
EndRem
?threaded
Function RunIRCHookThread:TThread(event:IRCEvent)
?Not threaded
Function RunIRCHookThread:Object(event:IRCEvent)
?
	?threaded
	Return TThread.Create(IRCHookThread, event)
	?Not threaded
	Return IRCHookThread(event)
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
