source doodle.tcl
source vm_client.tcl

VM_Client::Init
set handle [VM_Client::Register 0.tcp.ngrok.io 10501 doodle'handle_remote]
doodle 400 400 $handle