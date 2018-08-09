# VM_Server --
#	Open the server listening socket
#	and enter the Tcl event loop
#
# Arguments:
#	port	The server's port number

proc VM_Server {port port_public} {
    set s [socket -server VMAccept $port]
    set s_public [socket -server VMAccept $port_public]
    vwait forever
}

# VM_Accept --
#	Accept a connection from a new client.
#	This is called after a new socket connection
#	has been created by Tcl.
#
# Arguments:
#	sock	The new socket connection to the client
#	addr	The client's IP address
#	port	The client's port number
	
proc VMAccept {sock addr port} {
    global g_vm

    # Record the client's information

    puts "Accept $sock from $addr port $port"
    set g_vm($sock) 1

    # Ensure that each "puts" by the server
    # results in a network transmission

    fconfigure $sock -buffering line

    # Set up a callback for when the client sends data

    fileevent $sock readable [list VM $sock]
	return
}

# VM --
#	This procedure is called when the server
#	can read data from the client
#
# Arguments:
#	sock	The socket connection to the client

proc VM {sock} {
    global g_vm
	
    # Check end of file or abnormal connection drop,
    # then g_vm data back to the client.

    if {[eof $sock] || [catch {gets $sock line}]} {
		close $sock
		puts "Close $g_vm($sock)"
		unset g_vm($sock)
    } else {
	    foreach other_sock [array names g_vm] {
		    if {$other_sock == $sock} {continue}
			puts $other_sock $line
			flush $other_sock
		}
    }
}