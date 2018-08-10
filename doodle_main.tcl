source doodle.tcl
source vm_client.tcl

VM_Client::Init
set handle [VM_Client::Register localhost 14000 doodle'handle_remote]
doodle 400 400 $handle