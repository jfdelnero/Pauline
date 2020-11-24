/*
//
// Copyright (C) 2019-2020 Jean-François DEL NERO
//
// This file is part of the Pauline control page
//
// Pauline control page may be used and distributed without restriction provided
// that this copyright statement is not removed from the file and that any
// derivative work contains the original copyright notice and the associated
// disclaimer.
//
// Pauline control page is free software; you can redistribute it
// and/or modify  it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Pauline control page is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//   See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pauline control page; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
//
*/

var ws;
var ws2;
var imageTimerVar;

function PaulineConnection()
{
	var ip = location.host;

	var addr = "ws://" + ip + ":8080";
	var addr2 = "ws://" + ip + ":8081";

	/*document.getElementById("txtServer").value = addr;*/

	doConnect(addr,addr2);
}

/* Establish connection. */
function doConnect(addr,addr2)
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

	/* Do connection. */
	ws2 = new WebSocket(addr2);

	/* Register events. */
	ws2.onopen = function()
	{
		imageTimerVar = setInterval(imageTimer, 250);
	};

	/* Deals with messages. */
	ws2.onmessage = function (evt)
	{
		var img = document.getElementById("imageAnalysis");
		var urlObject = URL.createObjectURL(evt.data);
		img.src = urlObject;
	};

	ws2.onclose = function()
	{
		clearInterval(imageTimerVar);
	};

}

function imageTimer() {
	ws2.send("get_image\n");
}

function updatepreviewsettings()
{
	var log = document.getElementById("taLog").value;
	var txt = "setpreviewimagesettings" + " " + (document.getElementById("graphtimexselection").value * 1000).toString()
										+ " " + document.getElementById("graphtimeyselection").value.toString()
										+ " " + (document.getElementById("graphoffsetxselection").value * 1000).toString()
										+ " " + (document.getElementById("ckbHIGHCONTRAST").checked + 0).toString()
										+ " " + (document.getElementById("ckbFATDOTS").checked + 0).toString()
										+ "\n";
	//alert(txt);
	if (typeof ws !== 'undefined')
	{
		ws.send(txt);
		document.getElementById("taLog").value += ("Send: " + txt + "\n");
	}
};

function updatedecoders()
{
	var log = document.getElementById("taLog").value;
	var txt = "setpreviewimagedecoders" + " ";

	if(document.getElementById("ckbISOMFM").checked)
	{
		txt += " ISOMFM";
	}

	if(document.getElementById("ckbISOFM").checked)
	{
		txt += " ISOFM";
	}

	if(document.getElementById("ckbAMIGAMFM").checked)
	{
		txt += " AMIGAMFM";
	}

	if(document.getElementById("ckbAPPLE").checked)
	{
		txt += " APPLE";
	}

	if(document.getElementById("ckbEEMU").checked)
	{
		txt += " EEMU";
	}

	if(document.getElementById("ckbTYCOM").checked)
	{
		txt += " TYCOM";
	}

	if(document.getElementById("ckbMEMBRAIN").checked)
	{
		txt += " MEMBRAIN";
	}

	if(document.getElementById("ckbARBURG").checked)
	{
		txt += " ARBURG";
	}

	if(document.getElementById("ckbAED6200P").checked)
	{
		txt += " AED6200P";
	}

	if(document.getElementById("ckbNORTHSTAR").checked)
	{
		txt += " NORTHSTAR";
	}

	if(document.getElementById("ckbHEATHKIT").checked)
	{
		txt += " HEATHKIT";
	}

	if(document.getElementById("ckbDECRX02").checked)
	{
		txt += " DECRX02";
	}

	txt += "\n";

	//alert(txt);
	if (typeof ws !== 'undefined')
	{
		ws.send(txt);
		document.getElementById("taLog").value += ("Send: " + txt + "\n");
	}
};

document.addEventListener("DOMContentLoaded", function(event)
{
/*
	document.getElementById("btConn").onclick = function()
	{
		var txt = document.getElementById("txtServer").value;
		doConnect(txt);
	};
*/

	var element = document.getElementById("btMsg");
	if( element )
	{
		element.onclick = function()
		{
			var txt = document.getElementById("txtMsg").value;
			var log = document.getElementById("taLog").value;

			ws.send(txt);
			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	}

	var element = document.getElementById("btReboot");
	if( element )
	{
		element.onclick = function()
		{
			var txt = "system reboot\n";
			var log = document.getElementById("taLog").value;

			ws.send(txt);
			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btHalt");
	if( element )
	{
		element.onclick = function()
		{
			var txt = "system halt\n";
			var log = document.getElementById("taLog").value;

			ws.send(txt);
			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	/* dump functions */
	var element = document.getElementById("btRecalibrate");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "recalibrate " + document.getElementById("drives-select").value.toString() + "\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btMove");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "movehead"  + " " + document.getElementById("drives-select").value.toString() 
			                      + " " + document.getElementById("trackselection").value.toString()
			                      + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                      + "\n";
			
			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btMoveUp");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "headstep" + " " + document.getElementById("drives-select").value.toString() 
			                     + " " + "1"
			                     + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                     + "\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btMoveDown");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "headstep" + " " + document.getElementById("drives-select").value.toString()
			                     + " " + "-1"
			                     + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
			                     + "\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btStop");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "stop\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btEject");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "ejectdisk " + document.getElementById("drives-select").value.toString() + "\n";

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("ckbALTRPM");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;

			if( document.getElementById("ckbALTRPM").checked )
			{
				var txt = "setio DRIVES_PORT_PIN02_OUT\n";
			}
			else
			{
				var txt = "cleario DRIVES_PORT_PIN02_OUT\n";
			}

			//alert(txt);
			ws.send(txt);

			document.getElementById("taLog").value += ("Send: " + txt + "\n");
		};
	};

	var element = document.getElementById("btReadTrack");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "index_to_dump" + " " + document.getElementById("txtIndexToDumpDelay").value.toString()
									  + "\n";

			txt += "dump_time" + " "  + document.getElementById("txtTrackDumpLenght").value.toString()
									  + "\n";

			if( document.getElementById("ckbAutoIndex").checked )
			{
				var mode = "AUTO_INDEX_NAME";
				var startindex = 1;

			}
			else
			{
				var mode = "MANUAL_INDEX_NAME";
				var startindex = document.getElementById("txtDumpStartIndex").value.toString();
			}

			txt += "dump" + " " + document.getElementById("drives-select").value.toString() + " -1 -1"
						  + " " + document.getElementById("headselection").value.toString()
						  + " " + document.getElementById("headselection").value.toString()
						  + " " + (document.getElementById("ckb50Mhz").checked + 0).toString()
						  + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
						  + " " + (document.getElementById("ckbIGNOREINDEX").checked + 0).toString()
						  + " " + "0"
						  + " " + "\"" + document.getElementById("txtDumpName").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpComment").value.toString() + "\""
						  + " " + startindex
						  + " " + mode
						  + " " + "\"" + document.getElementById("txtDriveInfos").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpOperator").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpComment2").value.toString() + "\""
						  + "\n";

			//alert(txt);
			document.getElementById("taLog").value += ("Send: " + txt + "\n");

			ws.send(txt);

		};
	};

	var element = document.getElementById("graphtimexselection");
	if( element )
	{
		element.onmouseup = function()
		{
			updatepreviewsettings();
		};
		element.ontouchend = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("graphoffsetxselection");
	if( element )
	{
		element.onmouseup = function()
		{
			updatepreviewsettings();
		};
		element.ontouchend = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("graphtimeyselection");
	if( element )
	{
		element.onmouseup = function()
		{
			updatepreviewsettings();
		};
		element.ontouchend = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("ckbHIGHCONTRAST");
	if( element )
	{
		element.onclick = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("ckbISOMFM");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbISOFM");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbAMIGAMFM");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbAPPLE");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbEEMU");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbTYCOM");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbMEMBRAIN");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbARBURG");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbAED6200P");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbNORTHSTAR");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbHEATHKIT");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbDECRX02");
	if( element )
	{
		element.onclick = function()
		{
			updatedecoders();
		};
	};

	var element = document.getElementById("ckbFATDOTS");
	if( element )
	{
		element.onclick = function()
		{
			updatepreviewsettings();
		};
	};

	var element = document.getElementById("btReadDisk");
	if( element )
	{
		element.onclick = function()
		{
			var log = document.getElementById("taLog").value;
			var txt = "index_to_dump" + " " + document.getElementById("txtIndexToDumpDelay").value.toString()
									  + "\n";

			txt += "dump_time" + " "  + document.getElementById("txtTrackDumpLenght").value.toString()
									  + "\n";

			if( document.getElementById("ckbAutoIndex").checked )
			{
				var mode = "AUTO_INDEX_NAME";
				var startindex = 1;
			}
			else
			{
				var mode = "MANUAL_INDEX_NAME";
				var startindex = document.getElementById("txtDumpStartIndex").value.toString();
			}

			txt += "dump" + " " + document.getElementById("drives-select").value.toString()
						  + " " + document.getElementById("txtDumpMinTrack").value.toString()
						  + " " + document.getElementById("txtDumpMaxTrack").value.toString()
						  + " " + ( (document.getElementById("ckbSIDE0").checked + 0) ^ 1).toString()
						  + " " + (document.getElementById("ckbSIDE1").checked + 0).toString()
						  + " " + (document.getElementById("ckb50Mhz").checked + 0).toString()
						  + " " + (document.getElementById("ckbDOUBLESTEP").checked + 0).toString()
						  + " " + (document.getElementById("ckbIGNOREINDEX").checked + 0).toString()
						  + " " + "0"
						  + " " + "\"" + document.getElementById("txtDumpName").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpComment").value.toString() + "\""
						  + " " + startindex
						  + " " + mode
						  + " " + "\"" + document.getElementById("txtDriveInfos").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpOperator").value.toString() + "\""
						  + " " + "\"" + document.getElementById("txtDumpComment2").value.toString() + "\""
						  + "\n";

			//alert(txt);
			document.getElementById("taLog").value += ("Send: " + txt + "\n");

			ws.send(txt);

		};
	};

});

