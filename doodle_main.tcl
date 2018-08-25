source $env(DOODLE_HOME)/doodle.tcl
source $env(DOODLE_HOME)/vm_client.tcl

lappend auto_path $env(DOODLE_MODULES)
package require pdf4tcl

VM_Client::Init
set handle [VM_Client::Register 192.168.2.244 14000 doodle'handle_remote]
doodle 400 400 $handle