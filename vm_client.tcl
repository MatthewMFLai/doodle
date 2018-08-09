#
# A client of the g_g_echo service.
#

namespace eval VM_Client {
    variable m_sock
	variable m_callback
	variable m_handle
	variable m_host
	variable m_port
	variable m_state
	
proc Init {} {
    variable m_sock
	variable m_callback
	variable m_handle
	variable m_host
	variable m_port
	variable m_state
	
	set m_state VM_DISCONNECTED
	set m_handle 0
	array set m_sock {}
	array set m_callback {}
	array set m_host {}
	array set m_port {}
	return
}

proc Rx {sock} {
    variable m_sock
	variable m_callback
    variable m_state
	
    # Check end of file or abnormal connection drop,
    # then g_echo data back to the client.

    if {[eof $sock] || [catch {gets $sock line}]} {
		close $sock
		set m_state VM_DISCONNECTED
	    foreach handle [array names m_sock] {
		    if {$m_sock($handle) == $sock} {
				puts "Handle $handle disconnected!"
				after idle [list VM_Client::Reconnect $handle]
				break
			}
		}
    } else {
	    foreach handle [array names m_sock] {
		    if {$m_sock($handle) == $sock} {
			    catch {$m_callback($handle) $line} rc
				break
			}
		}
    }
}

proc Register {host port callback} {
    variable m_sock
	variable m_callback
	variable m_handle
	variable m_host
	variable m_port
	variable m_state

    if {[catch {socket $host $port} sock]} {
	    return -1
	} else {
        set m_state VM_CONNECTED	
	}
    fconfigure $sock -buffering line

    # Set up a callback for when the client sends data
    fileevent $sock readable [list VM_Client::Rx $sock]
	
	set rc $m_handle
	set m_sock($m_handle) $sock
	set m_callback($m_handle) $callback
	set m_host($m_handle) $host
	set m_port($m_handle) $port
	incr m_handle
    return $rc
}

proc Reconnect {handle} {
    variable m_sock
	variable m_callback
	variable m_handle
	variable m_host
	variable m_port
	variable m_state
	
    if {[catch {socket $m_host($handle) $m_port($handle)} sock]} {
	    return -1
	} else {
        set m_state VM_CONNECTED	
	}
    fconfigure $sock -buffering line

    # Set up a callback for when the client sends data
    fileevent $sock readable [list VM_Client::Rx $sock]
	
	set m_sock($handle) $sock
    return 0
}

proc Tx {handle data} {
    variable m_sock
    variable m_state
	
	if {$m_state != "VM_CONNECTED"} {
	    return
	}
	
    if {![info exists m_sock($handle)]} {
	    return
	}
	puts $m_sock($handle) $data
	flush $m_sock($handle)
	return
}
 
}