# The page routines and data structure
# g_page(current) is the current page. Page starts from 1.
# g_page(<page#>) = {{{list of coords} {list of config}}
#                    {{list of coords} {list of config}}
#					 {{list of coords} {list of config}}
#					 ...}

proc page_init {p_pages} {
    upvar $p_pages pages
	
	foreach idx [array names pages] {
	    unset pages($idx)
	}
    set pages(current) 1
    set pages(1) ""    
	return
}

proc page_current {p_pages} {
    upvar $p_pages pages

    return $pages(current)
}

proc page_numbers {p_pages} {
    upvar $p_pages pages
	
	set tmplist [array names pages]
	set idx [lsearch $tmplist "current"]
	return [lsort [lreplace $tmplist $idx $idx]]
}

proc page_next {p_pages} {
    upvar $p_pages pages
	
    set pagenum $pages(current)
	incr pagenum
	if {![info exists pages($pagenum)]} {
	    set pages($pagenum) ""
	}
	set pages(current) $pagenum
	return $pagenum
}

proc page_prev {p_pages} {
    upvar $p_pages pages
	
    set pagenum $pages(current)
	incr pagenum -1
	if {[info exists pages($pagenum)]} {
	    set pages(current) $pagenum
	} else {
	    incr pagenum
	}
	return $pagenum
}

proc page_load {p_pages serialdata} {
    upvar $p_pages pages
	
	foreach idx [array names pages] {
	    unset pages($idx)
	}
    array set pages $serialdata
	
	unset pages(current)
	set lastpage [lindex [lsort [array names pages]] end]
	set pages(current) $lastpage
	return
}

proc page_get_serial {p_pages} {
    upvar $p_pages pages
	
    return [array get pages]
}

proc page_get {p_pages page} {
    upvar $p_pages pages
	
	if {![info exist pages($page)]} {
	    return ""
	}
	return $pages($page)
}

proc page_set_serial {p_pages data} {
    upvar $p_pages pages
	
    array set pages $data
	return
}

proc page_set {p_pages page datalist} {
    upvar $p_pages pages
	
	set pages($page) $datalist
}
# Enf of the page routines and data structure

# The undo routines and data structure
proc undo_init {p_id_list} {
    upvar $p_id_list id_list
	
	set id_list ""
	return
}

proc undo_push {p_id_list id} {
    upvar $p_id_list id_list
	
	lappend id_list $id
	return
}

proc undo_pop {p_id_list} {
    upvar $p_id_list id_list
	
	set rc [lindex $id_list end]
	set id_list [lrange $id_list 0 end-1]
	return $rc
}

proc undo_peep_all {p_id_list} {
    upvar $p_id_list id_list
	
	return $id_list
}
# Enf of the undo routines and data structure

proc doodle {x y handle} {
   global w
   global g_handle
   global g_id_list
   global g_pages_db
   
   set w  .canvas
   if ![winfo exists $w] {
      wm withdraw .
      toplevel    $w
      wm geometry $w $x\x$y
      wm title    $w Canvas
      pack [canvas $w.c -bg white] -fill both -expand 1
      doodle'bind   $w.c
      interp alias {} c {} $w.c
      palette $w.c
      set ::color black; set ::width 1
   }
   wm deiconify $w; focus -force $w
   set g_handle $handle
   undo_init g_id_list
   page_init g_pages_db
 }
 
 proc palette w {
   set x 5; set y 5
   foreach color {black blue cyan green yellow orange red magenta} {
      $w create oval $x $y [expr $x+12] [expr $y+12] -fill $color -tag pal
      incr x 14
   }
   incr y 7
   $w bind pal <1> {palette'color %W}
   foreach width {1 2 3 4 5 6 7 8} {
      $w create line $x $y [expr $x+10] $y -width $width -tag width
      incr x 12
   }
   $w bind width <1> {palette'width %W}
   incr x 5
   $w create text $x $y -text C -tag clear
   $w bind clear <1> {global g_id_list; %W delete line;undo_init g_id_list; doodle'tx V-C 0 0}
   incr x 10
   $w create text $x $y -text U -tag undo
   $w bind undo <1> {global g_id_list;%W delete [undo_pop g_id_list]; doodle'tx V-U 0 0}
   incr x 10
   $w create text $x $y -text \< -tag prevpage
   $w bind prevpage <1> {doodle'update'page %W prev; doodle'tx V-Page prev 0}
   incr x 10
   $w create text $x $y -text \> -tag nextpage
   $w bind nextpage <1> {doodle'update'page %W next; doodle'tx V-Page next 0}
   incr x 10
   $w create text $x $y -text L -tag load
   $w bind load <1> {doodle'load %W}
   incr x 10
   $w create text $x $y -text S -tag save
   $w bind save <1> {doodle'save %W}
   incr x 10
   $w create text $x $y -text Q -tag quit
   $w bind quit <1> {exit 0}
 }
 proc palette'color w {
    $w itemconfig pal -width 1
    $w itemconfig current -width 3
    set ::color [$w itemcget current -fill]
	doodle'tx V-Color $::color 0
 }
 proc palette'width w {
    $w itemconfig width -fill black
    $w itemconfig current -fill red
    set ::width [$w itemcget current -width]
	doodle'tx V-Width $::width 0
 }
 
 proc doodle'bind w {
	bind $w <1>         {doodle'start %W %x %y; doodle'tx V-1 %x %y}
    bind $w <B1-Motion> {doodle'move %W %x %y; doodle'tx V-B1-Motion %x %y}
	bind $w <<V-1>>        {doodle'start %W %x %y}
    bind $w <<V-B1-Motion>> {doodle'move %W %x %y}
 }
 
 proc doodle'start {w x y} {
      global g_id_list

      if {$y<20} return ;# don't write on the palette
        set ::_id [$w create line $x $y $x $y \
        -fill $::color -width $::width -tag line]
      undo_push g_id_list $::_id		
 }
 
 proc doodle'move {w x y} {	 
      if {$y<20} return ;# don't write on the palette
        $w coords $::_id [concat [$w coords $::_id] $x $y]
 }
 
 proc doodle'save'page {w page_cur} {
     global g_id_list
     global g_pages_db
	 
	 set data ""
	 foreach id [undo_peep_all g_id_list] {
	     set coords [$w coords $id]
		 set config "-fill [$w itemcget $id -fill] -width [$w itemcget $id -width]"
		 lappend data [list $coords $config]	 
	 }
	 page_set g_pages_db $page_cur $data
	 return
 }
 
 proc doodle'load'page {w page_cur} {
     global g_id_list
     global g_pages_db
	 
	 foreach data [page_get g_pages_db $page_cur] {
	     set coords [lindex $data 0]
		 set x [lindex $coords 0]
		 set y [lindex $coords 1]
		 set ::_id [$w create line $x $y $x $y -tag line]
		 undo_push g_id_list $::_id
		 set coords [lrange $coords 2 end]
		 $w coords $::_id $coords
		 set configlist [lindex $data 1]
		 foreach {option val} $configlist {
             $w itemconfig $::_id $option $val
         }		 
	 }
	 return
 }
 
 proc doodle'update'page {w direction} {
     global g_id_list
     global g_pages_db

     set page_cur [page_current g_pages_db]
	 doodle'save'page $w $page_cur

	 if {$direction == "curr"} {
	     return
     }

	 undo_init g_id_list
	 $w delete line

	 if {$direction == "prev"} {
	     page_prev g_pages_db
	 } elseif {$direction == "next"} {
	     page_next g_pages_db
	 } else {
	 }
     set page_cur [page_current g_pages_db]
     doodle'load'page $w $page_cur	 
     return
 }
 
 proc doodle'load {w} {
     global g_pages_db
     global g_id_list

     set filename [tk_getOpenFile]
     if {$filename == ""} {
	     return
	 }

     set fd [open $filename r]
	 set data [read $fd]
	 close $fd

	 undo_init g_id_list
	 $w delete line
	 page_init g_pages_db
	 page_set_serial g_pages_db $data
	 set page_cur [page_current g_pages_db]
	 doodle'load'page $w $page_cur
	 
     return	 
 }
 
 proc doodle'save {w} {
     global g_pages_db

     doodle'update'page $w curr
	 set data [page_get_serial g_pages_db]
     set filename [tk_getSaveFile]
     if {$filename == ""} {
	     return
	 }
     set fd [open $filename w]
     puts $fd $data
     close $fd
     return	 
 }
 
  proc doodle'output'pdf {w filename} {
     global g_pages_db
     global g_id_list

     doodle'update'page $w curr

	 pdf4tcl::new mypdf -paper a4 -margin 15mm 
	 foreach page [page_numbers g_pages_db] {
	     undo_init g_id_list
	     $w delete line
	     doodle'load'page $w $page
		 mypdf startPage
		 mypdf canvas $w
	 }
     mypdf write -file $filename
     mypdf destroy
	 
	 undo_init g_id_list
	 $w delete line
	 doodle'load'page $w [page_current g_pages_db]
     return	 
 }
 
 proc doodle'tx {v_event x y} {
      global g_handle
	
      if {$y<20 &&
	      $v_event != "V-C" &&
		  $v_event != "V-U" &&
		  $v_event != "V-Width" &&
		  $v_event != "V-Page" &&
		  $v_event != "V-Color"} {
		  return
      }
	  VM_Client::Tx $g_handle "$v_event $x $y"
	  return
 }

 proc doodle'handle_remote {line} {
    global w
	global g_id_list
	
	set cmd [lindex $line 0]
	set x [lindex $line 1]
	set y [lindex $line 2]
	if {$cmd == "V-1"} {
		event generate $w.c <<V-1>> -x $x -y $y
	} elseif {$cmd == "V-B1-Motion"} {
		event generate $w.c <<V-B1-Motion>> -x $x -y $y
	} elseif {$cmd == "V-C"} {
		$w.c delete line
		undo_init g_id_list
	} elseif {$cmd == "V-U"} {
		$w.c delete [undo_pop g_id_list]
	} elseif {$cmd == "V-Width"} {
		set ::width $x
	} elseif {$cmd == "V-Color"} {
		set ::color $x
	} elseif {$cmd == "V-Page"} {
		doodle'update'page $w.c $x
	} else {
	}
	return
 }