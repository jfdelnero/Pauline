var ws;

function PaulineConnection()
{
    var ip = location.host;

	var addr = "ws://" + ip + ":8080";

	/*document.getElementById("txtServer").value = addr;*/

	doConnect(addr);
}

/* Establish connection. */
function doConnect(addr)
{
	/* Message to be sent. */
	var msg;

	/* Do connection. */
	ws = new WebSocket(addr);

	/* Register events. */
	ws.onopen = function()
	{
		document.getElementById("taLog").value += ("Connection opened\n");
	};

	/* Deals with messages. */
	ws.onmessage = function (evt) 
	{	
		document.getElementById("taLog").value += ("Recv: " + evt.data + "\n");
	};

	ws.onclose = function()
	{
		document.getElementById("taLog").value += ("Connection closed\n");
	};
}

document.addEventListener("DOMContentLoaded", function(event)
{
/*
	document.getElementById("btConn").onclick = function()
	{
		var txt = document.getElementById("txtServer").value;
		doConnect(txt);
	};
*/

	document.getElementById("btMsg").onclick = function()
	{
		var txt = document.getElementById("txtMsg").value;
		var log = document.getElementById("taLog").value;

		ws.send(txt);
		document.getElementById("taLog").value += ("Send: " + txt + "\n");
	};

	document.getElementById("btReboot").onclick = function()
	{
		var txt = "system reboot";
		var log = document.getElementById("taLog").value;

		ws.send(txt);
		document.getElementById("taLog").value += ("Send: " + txt + "\n");
	};

	document.getElementById("btHalt").onclick = function()
	{
		var txt = "system halt";
		var log = document.getElementById("taLog").value;

		ws.send(txt);
		document.getElementById("taLog").value += ("Send: " + txt + "\n");
	};

});

