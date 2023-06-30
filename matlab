#!/bin/sh

# Copyright 1984-2021 The MathWorks, Inc.
#
#  Name:
#     matlab    script file for invoking MATLAB
#
#  Usage:
#     matlab [-h|-help] | [-n | -e]
#        [-arch | v=variant | v=arch/variant]
#        [-c licensefile] [-display Xdisplay | -nodisplay]
#        [-nosplash] [-mwvisual visualid] [-debug]
#            [-softwareopengl | -nosoftwareopengl]
#        [-desktop | -nodesktop | -nojvm]
#            [-jdb [port]]
#        [-batch MATLAB_command | -r MATLAB_command]
#        [-sd folder | -useStartupFolderPref]
#        [-logfile logfile]
#        [-Ddebugger [options]]
#
#  Description:
#     This Bourne Shell script sets MATLAB environment variables,
#     determines the machine architecture, and starts the appropriate
#     executable.
#
#  Options:
#
#     -h,-help
#
#           Help. Show command usage
#
#     -n
#
#       Print out the values of the environment variables and
#       arguments passed to the MATLAB executable as well as
#       other diagnostic information. MATLAB is not run.
#
#     -e
#
#       Print ALL environment variables and their values to
#           standard output just prior to exiting. This argument
#       must have been parsed before exiting for anything to
#       be printed. MATLAB is not run. The last possible exiting
#           point is just before the MATLAB image would have been
#           executed and a status of 0 is returned. If the exit
#           status is not 0 on return then the variables and values
#           may not be correct.
#
#     -arch
#
#       Run MATLAB assuming this architecture rather than the
#       actual machine architecture.
#
#     v=variant
#
#           Execute the version of MATLAB found in the directory
#       bin/$ARCH/variant instead of bin/$ARCH.
#
#     v=arch/variant
#
#           Execute the version of MATLAB found in the directory
#       bin/arch/variant instead of bin/$ARCH.
#
#
#     -c licensefile
#
#           Set location of the license file that MATLAB should use.
#           It can have the form port@host or be a colon separated
#           list of license files.  This option will cause the
#           LM_LICENSE_FILE and MLM_LICENSE_FILE environment variables
#           to be ignored.
#
#     -display Xdisplay
#
#       Send X commands to X Window Server display, Xdisplay. This
#       supersedes the value of the DISPLAY environment variable.
#
#     -nodisplay
#
#       Do not display any X commands. The DISPLAY environment
#       variable is ignored. The MATLAB desktop will not be started.
#       However, unless -nojvm is also provided the Java virtual
#       machine will be started.
#
#     -nosplash
#
#           Do not display the splash screen during startup.
#
#     -mwvisual visualid
#
#           The default X visual to use for figure windows.
#           The visualid is a hex number which can be found using
#           xdpyinfo.
#
#     -softwareopengl
#
#           Force MATLAB to start with software OpenGL
#           libraries. Not available on macOS.
#
#     -nosoftwareopengl
#
#           Disable auto-selection of software OpenGL when a graphics driver
#           with known issues is detected. Not available on macOS.
#
#     -noopengl
#
#           Disable OpenGL completely and use painters instead.
#
#     -debug
#
#           Provides debugging information especially for X based
#       problems. Should be used only in conjunction with a
#       Technical Support Representative from The MathWorks, Inc.
#
#     -desktop
#
#           Allow the MATLAB desktop to be started by a process
#           without a controlling terminal. This is usually a required
#           command line argument when attempting to start MATLAB
#           from a window manager menu or desktop icon.
#
#     -nodesktop
#
#       Do not start the MATLAB desktop. Use the current window
#       for commands. The Java virtual machine will be started.
#
#     -nojvm
#
#       Shut off all Java support by not starting the Java virtual
#       machine. In particular the MATLAB desktop will not be
#       started.
#
#     -jdb [port]
#
#           Enable remote Java debugger on port (default 4444)
#
#     -batch MATLAB_command
#
#       Start MATLAB and execute the MATLAB command(s) with no desktop
#       and certain interactive capabilities disabled. Terminates
#       upon successful completion of the command and returns exit
#       code 0. Upon failure, MATLAB terminates with a non-zero exit.
#       Cannot be combined with -r.
#
#     -r MATLAB_command
#
#       Start MATLAB and execute the MATLAB command.
#       Cannot be combined with -batch.
#
#     -sd folder
#
#       Set the MATLAB startup folder to folder, specified as a string.
#       Cannot be combined with -useStartupFolderPref.
#
#     -useStartupFolderPref
#
#       Set the MATLAB startup folder to the value specified by
#       the Initial working folder option in the General Preferences panel.
#       Cannot be combined with -sd.
#
#     -logfile log
#
#       Make a copy of any output to the command window in file log.
#       This includes all crash reports.
#
#     -Ddebugger [options]
#
#       Start MATLAB with debugger (e.g. gdb, lldb).
#       A full path can be specified for debugger. The options
#       cover ONLY those that go after the executable to be debugged
#       in the syntax of the actual debug command and for most
#       debuggers this is very limited. To customize your debugging
#       session use a startup file. See your debugger documentation
#       for details. Options above that would normally be passed to
#       the MATLAB executable should be used as parameters of
#       a command inside the debugger like 'run' and not used
#       when running the matlab script. If any of the options are
#       placed before the -Ddebugger argument they will be
#       handled as if they were part of the options after the
#       -Ddebugger argument and will be treated as illegal
#       options by most debuggers. The MATLAB_DEBUG environment
#       variable is set to the filename part of the debugger argument.
#
#       NOTE: For certain debuggers like gdb, the SHELL environment
#         variable is ALWAYS set to /bin/sh.
#
#__________________________________________________________________________
#
# Enable proper operation on Windows when using a UNIX-compatible shell
# Simply redirects to the Windows starter executable.
#
    if [ "$OS" = "Windows_NT" ]; then
        arglist=
        while [ $# -gt 0 ]; do
            # Quote arguments to preserve arguments that contain whitespace
            # or single quotes, e.g., -r "disp('hello'); quit"
            arglist="$arglist \"$1\""
            shift
        done
        eval exec "\"$0.exe\" $arglist"
    fi
#
    arg0_=$0

# Determine temporary directory for storing log files
    if [ -n "${TMPDIR}" ]; then
        temp_dir="${TMPDIR}"
    elif [ -n "${TMP}" ]; then
        temp_dir="${TMP}"
    else
        temp_dir=/tmp
    fi

#
# Temporary file that hold MATLABPATH code from .matlab7rc.sh file.
#
    temp_file="${temp_dir}"/matlab.$LOGNAME.$$.a
#
    trap "rm -f $temp_file; exit 1" 1 2 3 15
#
# Some Bourne shells use builtin echo that doesn't preserve backslashes
# in certain cases, e.g. echo "'a\nb'"
#
# Need version of non-builtin echo that will preserve the backslash.
#
    if [ -x /bin/echo ]; then   # On Linux and Mac, /bin/echo does it.
        ECHO=/bin/echo
    else
        ECHO=echo
    fi

#========================= archlist.sh (start) ============================
#
# usage:        archlist.sh
#
# abstract:     This Bourne Shell script creates the variable ARCH_LIST.
#
# note(s):      1. This file is always imbedded in another script
#
# Copyright 1997-2013 The MathWorks, Inc.
#----------------------------------------------------------------------------
#
    ARCH_LIST='glnxa64 linux-arm-64 maca64 maci64'
#=======================================================================
# Functions:
#   check_archlist ()
#=======================================================================
    check_archlist () { # Sets ARCH. If first argument contains a valid
			# arch then ARCH is set to that value else
		        # an empty string. If there is a second argument
			# do not output any warning message. The most
			# common forms of the first argument are:
			#
			#     ARCH=arch
			#     MATLAB_ARCH=arch
			#     argument=-arch
			#
                        # Always returns a 0 status.
                        #
                        # usage: check_archlist arch=[-]value [noprint]
                        #
	if [ $# -gt 0 ]; then
	    arch_in=`expr "$1" : '.*=\(.*\)'`
	    if [ "$arch_in" != "" ]; then
	        ARCH=`echo "$ARCH_LIST EOF $arch_in" | awk '
#-----------------------------------------------------------------------
	{ for (i = 1; i <= NF; i = i + 1)
	      if ($i == "EOF")
		  narch = i - 1
	  for (i = 1; i <= narch; i = i + 1)
		if ($i == $NF || "-" $i == $NF) {
		    print $i
		    exit
		}
	}'`
#-----------------------------------------------------------------------
	       if [ "$ARCH" = "" -a $# -eq 1 ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ' '
echo "    Warning: $1 does not specify a valid architecture - ignored . . ."
echo ' '
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	       fi
	    else
		ARCH=""
	    fi
	else
	    ARCH=""
	fi
#
	return 0
    }
#=======================================================================
#========================= archlist.sh (end) ==============================
#
#=======================================================================
# Functions:
#   check_rc_file ()
#   build_cmd ()
#=======================================================================
    check_rc_file () { # Checks rc_file file for minimal features.
                       # Currently the only thing it checks for is:
                       #
                       #    .matlab7rc.sh in the file
                       #
                       # If it fails the check print a warning message.
                       # The rc_file is assumed to exist.
                       #
                       # Always returns a zero status.
                       #
                       # usage: check_rc_file rc_file
                       #
        grep '\.matlab7rc.sh' "$1" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo "---------------------------------------------------------------------------"
echo "Warning: The .matlab7rc.sh file that was sourced is old . . ."
echo "         --> file = $1"
echo " "
echo '         Please use $MATLAB/bin/.matlab7rc.sh to update this file.'
echo "         --> MATLAB = $MATLAB"
echo "---------------------------------------------------------------------------"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        fi
        return 0
    }
#=======================================================================
    build_cmd () { # Takes the cmd input string and outputs the same
                   # string correctly quoted to be evaluated again.
                   #
                   # Always returns a 0
                   #
                   # usage: build_cmd
                   #

        # Use version of echo here that will preserve
        # backslashes within $cmd. - g490189

        $ECHO "$cmd" | sed s/\'/\'\"\'\"\'/g | awk -v quote="'" '{print quote $0 quote}'

        return 0
    }
#=======================================================================
#
#**************************************************************************
# Determine the path of the MATLAB root directory - always one directory
# up from the path to this command.
#**************************************************************************
#
    filename=$arg0_
#
# Now it is either a file or a link to a file.
#
    cpath=`pwd`

#
# Use it to find the top of the tree
# Skip this if someone wants to override the default
#
    if [ "$SOURCE_MATLAB_ENV_FROM" = "" ]; then

#
# Follow up to 8 links before giving up. Same as BSD 4.3
#
      n=1
      maxlinks=8
      while [ $n -le $maxlinks ]
      do
#
# Get directory correctly!
#
    newdir=`echo "$filename" | awk '
                        { tail = $0
                          np = index (tail, "/")
                          while ( np != 0 ) {
                             tail = substr (tail, np + 1, length (tail) - np)
                             if (tail == "" ) break
                             np = index (tail, "/")
                          }
                          head = substr ($0, 1, length ($0) - length (tail))
                          if ( tail == "." || tail == "..")
                             print $0
                          else
                             print head
                        }'`
    if [ ! "$newdir" ]; then
        newdir="."
    fi
    (cd "$newdir") > /dev/null 2>&1
    if [ $? -ne 0 ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo ''
    echo 'Internal error 1: We could not determine the path of the'
    echo '                  MATLAB root directory.'
    echo ''
    echo "                  original command path = $arg0_"
    echo "                  current  command path = $filename"
    echo ''
    echo '                  Please contact:'
    echo ''
    echo '                      MathWorks Technical Support'
    echo ''
    echo '                  for further assistance.'
    echo ''
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        exit 1
    fi
    cd "$newdir"
#
# Need the function pwd - not the built in one
#
    newdir=`/bin/pwd`
#
    newbase=`expr //$filename : '.*/\(.*\)' \| $filename`
        lscmd=`ls -l $newbase 2>/dev/null`
    if [ ! "$lscmd" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo ''
    echo 'Internal error 2: Could not determine the path of the'
    echo '                  MATLAB root directory.'
    echo ''
    echo "                  original command path = $filename"
    echo "                  current  command path = $filename"
    echo ''
    echo '                  Please contact:'
    echo ''
    echo '                      MathWorks Technical Support'
    echo ''
    echo '                  for further assistance.'
    echo ''
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        exit 1
    fi
#
# Check for link portably
#
    if [ `expr "$lscmd" : '.*->.*'` -ne 0 ]; then
        filename=`echo "$lscmd" | awk '{ print $NF }'`
    else
#
# It's a file
#
        dir="$newdir"
        command="$newbase"
#
        cd "$dir"/..
#
# On the Mac, the -P option to pwd causes it to return a resolved path, but
# on 10.5 and later, -P is no longer the default, so we are now passing -P explicitly.
#
        if [ "$ARCH" = "" ]; then
# If we are on the Mac then /bin/pwd will not return a resolved path. This is ok
# because the whole point here is to source $MATLABROOT/bin/util/arch.sh which will
# set $ARCH.
            MATLABdefault=`/bin/pwd`
            . "$MATLABdefault/bin/util/arch.sh"
        fi
        if [ "$ARCH" = 'maca64' -o "$ARCH" = 'maci64' ]; then
            MATLABdefault=`/bin/pwd -P`
#
# The Linux version of pwd returns a resolved path by default, and there is
# no -P option
#
        else
            MATLABdefault=`/bin/pwd`
        fi
        break
    fi
    n=`expr $n + 1`
      done
      if [ $n -gt $maxlinks ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo ''
    echo 'Internal error 3: More than $maxlinks links in path to'
    echo "                  this script. That's too many!"
    echo ''
    echo "                  original command path = $filename"
    echo "                  current  command path = $filename"
    echo ''
    echo '                  Please contact:'
    echo ''
    echo '                      MathWorks Technical Support'
    echo ''
    echo '                  for further assistance.'
    echo ''
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    exit 1
      fi
    else
        MATLABdefault="$SOURCE_MATLAB_ENV_FROM"
    fi

    cd "$cpath"
#
#**************************************************************************
#
# Do not use ARCH if it exists in the environment
#
    ARCH=""
#
# Parse the arguments
#
    stat="OK"
    showenv=0
    showenv_all=0
    VARIANT=""
    VARIANTmatlab="MATLAB"
    arglist=""
    arglist2=
    memmgr=""
    desktopflag="default"
    jvmflag=1
    awtflag=1
    batchflag=0
    nodisplay=0
    usemesa=0
    nousemesa=0
    noopengl=0
    workerflag=0
    while [ "$stat" = "OK" -a  $# -gt 0 ]; do
    case "$1" in
        -h|-help)
        stat=""
        ;;
            -n)
                showenv=1
                ;;
        -e)
            showenv_all=1
        ;;
        -c)
        if [ $# -eq 1 ]; then
            arglist="$arglist $1"
        else
            arglist="$arglist $1 '$2'"
            shift
        fi
        ;;
        -display)
        if [ $# -eq 1 ]; then
            stat=""
        else
            arglist="$arglist $1"
            shift
            isoption=`expr "/$1" : '/\(-.*\)'`
            if [ "$isoption" != "" ]; then
                stat=""
            else
                arglist="$arglist $1"
            display="$1"
            fi
        fi
        ;;
        -nodisplay)
        arglist="$arglist $1"
        nodisplay=1
        ;;
        -noawt)
        arglist="$arglist $1"
        awtflag=0
        ;;
        -softwareopengl)
        usemesa=1;
                arglist="$arglist $1"
        ;;
        -softwareopengllinux)
        usemesa=1;
                arglist="$arglist -softwareopengl"
        ;;
            -nosoftwareopengl)
                nousemesa=1;
                arglist="$arglist $1"
                ;;
            -noopengl)
                noopengl=1;
                arglist="$arglist $1"
                ;;
        -memmgr)
        if [ $# -eq 1 ]; then
            stat=""
        else
            shift
            memmgr=$1
        fi
        ;;
        -D*)
        debugger=`expr "$1" : '-D\(.*\)'`
        if [ "$debugger" = "" ]; then
            stat=""
        else
            MATLAB_DEBUG=`expr "//$debugger" : ".*/\(.*\)"`
        fi
        ;;
        -jdb)
        arglist="$arglist $1"
        ;;
        -nodesktop)
        desktopflag="nodesktop"
        ;;
        -desktop)
        desktopflag="desktop"
        arglist="$arglist $1"
        ;;
        -nojvm)
        jvmflag=0
        ;;
        -dmlworker)
        workerflag=1
        arglist="$arglist $1"
        ;;
        -parallelserver)
        workerflag=1
        arglist="$arglist $1"
        ;;
        -app | -batch | -r)
        if [ $# -eq 1 ]; then
            stat=""
        else
            if [ "$1" = "-batch" ]; then
                batchflag=1
            fi
            arglist="$arglist $1"
            shift
            cmd="$1"
            quoted_cmd=`build_cmd`
                    # Use version of echo here that will preserve
                    # backslashes in $quoted_cmd. - g490189
            arglist="$arglist `$ECHO $quoted_cmd`"
        fi
        ;;
        -timing)
                timingWanted=1
        if [ "$ARCH" = "" ]; then
                    . "$MATLABdefault/bin/util/arch.sh"
                fi
                if [ -f "$MATLABdefault/bin/$ARCH/cpucount" ]; then
                    MATLAB_CPUCOUNT=`"$MATLABdefault/bin/$ARCH/cpucount"`
                fi
        ;;
        -plt)
	    LANG="fi_FI.utf8"
	    export LANG
        ;;
        -logfile)
        if [ $# -eq 1 ]; then
#
# The MATLAB executable will check that there is no logfile
#
            arglist="$arglist $1"
        else
#
# The MATLAB executable will check if the file can be opened for writing
#
            arglist="$arglist $1 '$2'"
            shift
        fi
        ;;
        -sd)
        if [ $# -eq 1 ]; then
            arglist="$arglist $1"
        else
            # add quotes around second argument to preserve spaces in path
            arglist="$arglist $1 '$2'"
            shift
        fi
        ;;
        v=*/*)
                foundVariant=0
#
# Test options if no debugger.
#
                if [ "$debugger" = "" ]; then
#
# Check for variant
#
                    value=`expr "$1" : 'v=\(.*\)/.*'`
                    value2=`expr "$1" : 'v=.*/\(.*\)'`
            arch=$ARCH
            check_archlist argument=$value noprint
            if [ "$ARCH" != "" -a -f "$MATLABdefault/bin/$value/$value2/MATLAB" ]; then
            VARIANT=$value2
            VARIANTmatlab=$VARIANT/MATLAB
                        foundVariant=1
            else
            ARCH=$arch
            fi
        fi
        if [ "$foundVariant" = "0" ]; then
                    arglist="$arglist $1"
        fi
        ;;
        v=*)
                foundVariant=0
#
# Test options if no debugger.
#
                if [ "$debugger" = "" ]; then
            value=`expr "$1" : 'v=\(.*\)'`
#
# Check for variant
#
            if [ "$ARCH" = "" ]; then
            . "$MATLABdefault/bin/util/arch.sh"
            fi
            if [ -f "$MATLABdefault/bin/$ARCH/$value/MATLAB" ]; then
            VARIANT=$value
            VARIANTmatlab=$VARIANT/MATLAB
            foundVariant=1
            fi
                fi
        if [ "$foundVariant" = "0" ]; then
                    arglist="$arglist $1"
        fi
        ;;
        -*)
        found=0
#
# Test options if no debugger.
#
                if [ "$debugger" = "" ]; then
#
# Check for -arch
#
            arch=$ARCH
            check_archlist argument=$1 noprint
            if [ "$ARCH" != "" ]; then
            found=1
            else
            ARCH=$arch
            fi
                fi
        if [ "$found" = "0" ]; then
                    arglist="$arglist $1"
        fi
                ;;
        *)
        arglist="$arglist $1"
        ;;
    esac
    shift
    done
#
# Check for errors
#
    if [ "$stat" != "OK" -a "$showenv" != "1" ]; then   # An error occurred.
#
        if [ "$stat" != "" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo ""
    echo "    ${command}:  $stat"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        fi
    if [ "$ARCH" = "" ]; then
        . "$MATLABdefault/bin/util/arch.sh"
    fi
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo ""
    echo "    Usage:  ${command} [-h|-help] | [-n | -e]"
    echo "                   [v=variant]"
    echo "                   [-c licensefile] [-display Xdisplay | -nodisplay]"
    echo "                   [--noFigureWindows]"
    echo "                   [-nosplash] [-debug]"
    echo "                   [-softwareopengl | -nosoftwareopengl]"
    echo "                   [-desktop | -nodesktop | -nojvm]"
    echo "                   [-batch MATLAB_command | -r MATLAB_command]"
    echo "                   [-sd folder | -useStartupFolderPref]"
    echo "                   [-logfile log]"
    echo "                   [-singleCompThread]"
    echo "                   [-jdb [port]]"
    echo "                   [-Ddebugger [options]]"
    echo "                   [-nouserjavapath]"
    echo ""
    echo "    -h|-help                - Display arguments."
    echo "    -n                      - Display final environment variables,"
    echo "                              arguments, and other diagnostic"
    echo "                              information. MATLAB is not run."
    echo "    -e                      - Display ALL the environment variables and"
    echo "                              their values to standard output. MATLAB"
    echo "                              is not run. If the exit status is not"
    echo "                              0 on return then the variables and values"
    echo "                              may not be correct."
    echo "    v=variant               - Start the version of MATLAB found"
    echo "                              in bin/$ARCH/variant instead of bin/$ARCH."
    echo "    -c licensefile          - Set location of the license file that MATLAB"
    echo "                              should use.  It can have the form port@host or"
    echo "                              be a colon separated list of license files."
    echo "                              The LM_LICENSE_FILE and MLM_LICENSE_FILE"
    echo "                              environment variables will be ignored."
    echo "    -display Xdisplay       - Send X commands to X server display, Xdisplay."
    echo "                              Linux only."
    echo "    -nodisplay              - Do not display any X commands. The MATLAB"
    echo "                              desktop will not be started. However, unless"
    echo "                              -nojvm is also provided the Java virtual machine"
    echo "                              will be started."
    echo "    -noFigureWindows        - Disables the display of figure windows in MATLAB."
    echo "    -nosplash               - Do not display the splash screen during startup."
    echo "    -softwareopengl         - Force MATLAB to start with software OpenGL"
    echo "                              libraries. Not available on macOS."
    echo "    -nosoftwareopengl       - Disable auto-selection of software OpenGL"
    echo "                              when a graphics driver with known issues is detected."
    echo "                              Not available on macOS."
    echo "    -debug                  - Provide debugging information especially for X"
    echo "                              based problems. Linux only."
    echo "    -desktop                - Allow the MATLAB desktop to be started by a"
    echo "                              process without a controlling terminal. This is"
    echo "                              usually a required command line argument when"
    echo "                              attempting to start MATLAB from a window manager"
    echo "                              menu or desktop icon."
    echo "    -nodesktop              - Do not start the MATLAB desktop. Use the current"
    echo "                              terminal for commands. The Java virtual machine"
    echo "                              will be started."
    echo "    -singleCompThread       - Limit MATLAB to a single computational thread. "
    echo "                              By default, MATLAB makes use of the multithreading "
    echo "                              capabilities of the computer on which it is running."
    echo "    -nojvm                  - Shut off all Java support by not starting the"
    echo "                              Java virtual machine. In particular the MATLAB"
    echo "                              desktop will not be started."
    echo "    -jdb [port]             - Enable remote Java debugging on port (default 4444)"
    echo "    -batch MATLAB_command   - Start MATLAB and execute the MATLAB command(s) with no desktop"
    echo "                              and certain interactive capabilities disabled. Terminates"
    echo "                              upon successful completion of the command and returns exit"
    echo "                              code 0. Upon failure, MATLAB terminates with a non-zero exit."
    echo "                              Cannot be combined with -r."
    echo "    -r MATLAB_command       - Start MATLAB and execute the MATLAB_command."
    echo "                              Cannot be combined with -batch."
    echo "    -sd folder              - Set the MATLAB startup folder to folder, specified as a string."
    echo "                              Cannot be combined with -useStartupFolderPref."
    echo "    -useStartupFolderPref   - Set the MATLAB startup folder to the value"
    echo "                              specified by the Initial working folder option"
    echo "                              in the General Preferences panel."
    echo "                              Cannot be combined with -sd."
    echo "    -logfile log            - Make a copy of any output to the command window"
    echo "                              in file log. This includes all crash reports."
    echo "    -Ddebugger [options]    - Start debugger to debug MATLAB."
    echo "    -nouserjavapath         - Ignore custom javaclasspath.txt and javalibrarypath.txt files."
    echo ""
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    if [ "$showenv_all" = "1" ]; then
       env
    fi
        exit 1
    fi
#
# Determine what is set in the environment
#
    AUTOMOUNT_MAPenv="$AUTOMOUNT_MAP"
    DISPLAYenv="$DISPLAY"
    TOOLBOXenv="$TOOLBOX"
    MATLABPATHenv="$MATLABPATH"
    MATLAB_MEM_MGRenv="$MATLAB_MEM_MGR"
    SHELLenv="$SHELL"
#
# Set the defaults - MATLABdefault is determined above.
#
    AUTOMOUNT_MAPdefault=''
    DISPLAYdefault=''
    ARCHdefault=''
    TOOLBOXdefault='$MATLAB/toolbox'
    MATLABPATHdefault=''
#
    MATLAB_MEM_MGRdefault=''
#
    SHELLdefault='$SHELL'
#
    MATLAB_UTIL_DIRdefault=$MATLABdefault/bin/util
#
# Feature state variables
#
#--------------------------------------------------------------------------
#
# Source file .matlab7rc.sh and get values for the following environment
# variables
#
#       ARCH                    (machine architecture)
#       AUTOMOUNT_MAP           (Path prefix map for automounting)
#       DISPLAY                 (DISPLAY variable for X Window System)
#       LDPATH_PREFIX           (path(s) that appear at the start of
#                    LD_LIBRARY_PATH)
#       LDPATH_SUFFIX           (path(s) that appear at the end of
#                    LD_LIBRARY_PATH)
#       LD_LIBRARY_PATH         (load library path - the name
#                    LD_LIBRARY_PATH is platform dependent)
#       MATLAB                  (MATLAB root directory)
#       MATLABPATH              (MATLAB search path)
#       SHELL                   (which shell to use for ! and unix
#                    command in MATLAB)
#       TOOLBOX                 (toolbox path)
#
# The search order for .matlab7rc.sh is:
#
#       .               (current directory)
#       $HOME           (users home directory)
#       $MATLAB/bin     (MATLAB bin directory)
#
    if [ -f .matlab7rc.sh ]; then
        SOURCED_DIR='.'
        SOURCED_DIReval=`pwd`
        . "$cpath"/.matlab7rc.sh
    elif [ -f "$HOME"/.matlab7rc.sh ]; then
        SOURCED_DIR='$HOME'
        SOURCED_DIReval=$HOME
        . "$HOME"/.matlab7rc.sh
    elif [ -f "$MATLABdefault/bin/.matlab7rc.sh" ]; then
#
# NOTE: At this point we will use the MATLAB determined earlier to
#       source the file. After that the value in that file if not
#       null will be used.
#
        SOURCED_DIR='$MATLAB/bin'
        SOURCED_DIReval=$MATLABdefault/bin
        . "$MATLABdefault/bin/.matlab7rc.sh"
    else
        SOURCED_DIR=
        MATLAB_UTIL_DIR=$MATLAB_UTIL_DIRdefault
#
# arch.sh requires MATLAB - save temporarily
#
        MATLABsave="$MATLAB"
        MATLAB="$MATLABdefault"
#
        . "$MATLAB_UTIL_DIR/arch.sh"
        if [ "$ARCH" = "unknown" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo ''
    echo '^G    Sorry! We could not determine the machine architecture for your'
    echo '           host. Please contact:'
    echo ''
    echo '               MathWorks Technical Support'
    echo ''
    echo '           for further assistance.'
    echo ''
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            exit 1
        fi
        MATLAB="$MATLABsave"
#
    ARCHdefault=$ARCH
    fi
#
#--------------------------------------------------------------------------
#
# Determine the final values for the following variables
#
#       ARCH                    (machine architecture)
#       AUTOMOUNT_MAP           (Path prefix map for automounting)
#       DISPLAY                 (DISPLAY variable for X Window System)
#       MATLAB                  (MATLAB root directory)
#       MATLAB_MEM_MGR          (Type of memory manager)
#       MATLAB_DEBUG        (name of the debugger from -Ddebugger argument)
#       MATLABPATH              (MATLAB search path)
#       SHELL                   (which shell to use for ! and unix
#                    command in MATLAB)
#       TOOLBOX                 (toolbox path)
#
    rcfile='r '
    environ='e '
    script='s '
    argument='a '
    rcfilep='rs'
    environp='es'
#
# Sourced a .matlab7rc.sh file
#
    if [ "$SOURCED_DIR" != "" ]; then
    if [ "$AUTOMOUNT_MAP" != "" ]; then
        if [ "$AUTOMOUNT_MAPenv" != "" ]; then
                AUTOMOUNT_MAPmode="$environ"
        else
                AUTOMOUNT_MAPmode="$rcfile"
        fi
    else
            AUTOMOUNT_MAPmode="$script"
        AUTOMOUNT_MAP="$AUTOMOUNT_MAPdefault"
    fi
#
        if [ "$MATLAB" != "" ]; then
            MATLABmode="$rcfile"
        else
            MATLABmode="$script"
            MATLAB="$MATLABdefault"
        fi
        if [ "$AUTOMOUNT_MAP" != "" ]; then
            MATLAB=`echo $MATLAB $AUTOMOUNT_MAP | awk '
                {if (substr($1,1,length($2)) == $2)
                     if (NF == 4)                               # a -> b
                         print $NF substr($1,length($2) + 1)
                     else                                       # a ->
                         print substr($1,length($2) + 1)
                     else
                         print $1}'`
        fi
#
    if [ "$display" != "" ]; then
            DISPLAYmode="$argument"
        DISPLAY="$display"
    elif [ "$DISPLAY" != "" ]; then
        if [ "$DISPLAYenv" = "$DISPLAY" ]; then
                DISPLAYmode="$environ"
        else
                DISPLAYmode="$rcfile"
        fi
    else
            DISPLAYmode="$script"
        DISPLAY="`eval echo $DISPLAYdefault`"
    fi
#
    if [ "$ARCH" != "" ]; then
            ARCHmode="$rcfile"
    else
            ARCHmode="$script"
        ARCH="$ARCHdefault"
    fi
#
    if [ "$TOOLBOX" != "" ]; then
        if [ "$TOOLBOXenv" = "$TOOLBOX" ]; then
                TOOLBOXmode="$environ"
        else
                TOOLBOXmode="$rcfile"
        fi
    else
            TOOLBOXmode="$script"
        TOOLBOX="`eval echo $TOOLBOXdefault`"
    fi
#
        if [ "$MATLABPATH" != "" ]; then
        if [ "$MATLABPATHenv" = "$MATLABPATH" ]; then
                MATLABPATHmode="$environp"
        else
                MATLABPATHmode="$rcfilep"
        fi
        else
            MATLABPATHmode="$script"
        MATLABPATH="`eval echo $MATLABPATHdefault`"
        fi
#
# For MATLAB_MEM_MGR:
#
#        1. memmgr manager argument
#        2. rcfile (not currently set)
#    3. environment
#    4. default (empty)
#
    if [ "$memmgr" != "" ]; then
        MATLAB_MEM_MGRmode="$argument"
        MATLAB_MEM_MGR=$memmgr
    elif [ "$MATLAB_MEM_MGR" != "" ]; then
        if [ "$MATLAB_MEM_MGRenv" = "$MATLAB_MEM_MGR" ]; then
            MATLAB_MEM_MGRmode="$environ"
        else
            MATLAB_MEM_MGRmode="$rcfile"
        fi
    else
        MATLAB_MEM_MGRmode="$script"
        MATLAB_MEM_MGR="$MATLAB_MEM_MGRdefault"
    fi
#
    if [ "$MATLAB_DEBUG" = "" ]; then
            MATLAB_DEBUGmode="$script"
    else
            MATLAB_DEBUGmode="$argument"
    fi
#
    if [ "$SHELL" != "" ]; then
        if [ "$SHELLenv" = "$SHELL" ]; then
                SHELLmode="$environ"
        else
                SHELLmode="$rcfile"
        fi
    else
            SHELLmode="$script"
        SHELL="`eval echo $SHELLdefault`"
    fi
    else
    if [ "$AUTOMOUNT_MAPenv" != "" ]; then
            AUTOMOUNT_MAPmode="$environ"
        AUTOMOUNT_MAP="$AUTOMOUNT_MAPenv"
    else
            AUTOMOUNT_MAPmode="$script"
        AUTOMOUNT_MAP="$AUTOMOUNT_MAPdefault"
    fi
    MATLABmode="$script"
        if [ "$AUTOMOUNT_MAP" != "" ]; then
            MATLAB=`echo $MATLABdefault $AUTOMOUNT_MAP | awk '
                {if (substr($1,1,length($2)) == $2)
                     if (NF == 4)                               # a -> b
                         print $NF substr($1,length($2) + 1)
                     else                                       # a ->
                         print substr($1,length($2) + 1)
                     else
                         print $1}'`
    else
        MATLAB="$MATLABdefault"
        fi
    if [ "$display" != "" ]; then
            DISPLAYmode="$argument"
        DISPLAY="$display"
    else
            DISPLAYmode="$environ"
        DISPLAY="$DISPLAYenv"
    fi
        ARCHmode="$script"
    ARCH="$ARCHdefault"
    TOOLBOXmode="$script"
    TOOLBOX="`eval echo $TOOLBOXdefault`"
        if [ "$MATLABPATHenv" != "" ]; then
            MATLABPATHmode="$environp"
        MATLABPATH="$MATLABPATHenv"
    else
            MATLABPATHmode="$script"
        MATLABPATH="`eval echo $MATLABPATHdefault`"
    fi
    if [ "$MATLAB_MEM_MGR" != "" ]; then
        MATLAB_MEM_MGRmode="$environ"
    else
        MATLAB_MEM_MGRmode="$script"
        MATLAB_MEM_MGR="$MATLAB_MEM_MGRdefault"
        fi
    if [ "$MATLAB_DEBUG" = "" ]; then
            MATLAB_DEBUGmode="$script"
    else
            MATLAB_DEBUGmode="$argument"
    fi
        SHELLmode="$environ"
    SHELL="$SHELLenv"
    fi
#
#--------------------------------------------------------------------------
#
# Check rc_file
#
    if [ "$SOURCED_DIR" = '.' ]; then
    check_rc_file "$cpath"/.matlab7rc.sh
    elif [ "$SOURCED_DIR" = '$HOME' ]; then
    check_rc_file "$HOME"/.matlab7rc.sh
    fi

#
# Use MATLAB instead of matlab for the executable
# A more invasive change (to be made long-term) involves setmwe
#
VARIANTmatlab=`echo "$VARIANTmatlab" | sed 's|matlab$|MATLAB|'`

#
# Determine the final values for the following variables
#
#       LD_LIBRARY_PATH         (load library path - the name
#                    LD_LIBRARY_PATH is platform dependent)
#   _JVM_THREADS_TYPE   (type of Java virtual machine threads)
#
#--------------------------------------------------------------------------

#
# Decide whether to put -nojvm or -nodesktop back on the argument list.
# Check the mac first.
#
if [ "$ARCH" = "maca64" -o "$ARCH" = 'maci64' ]; then
#
# If the user did not explicitly set v=arch or v=arch/variant,
# then launch the executable via the Mac OS X package by default, so that
# resources and executable icons can be automatically found by the system.
# Filter out noawt and nodisplay.
#
    if [ "$foundVariant" = "" -a "$awtflag" = '1' -a "$nodisplay" = '0' ]; then
        VARIANT=../../Contents/MacOS
        VARIANTmatlab=$VARIANT/MATLAB_$ARCH
    fi
fi
if [ "$jvmflag" = "0" ]; then
    arglist="$arglist -nojvm"
elif [ "$desktopflag" = "nodesktop" ]; then
    arglist="$arglist -nodesktop"
fi

#
# Determine the java vm path for each platform.
#
    case "$ARCH" in
    maca64)
        JARCH="."
        ;;
    maci64)
        JARCH="."
        ;;
    glnxa64)
        JARCH="amd64"
        ;;
    *)
        JARCH=$ARCH
        ;;
    esac

    DEFAULT_JRE_LOC=$MATLAB/sys/java/jre/$ARCH/jre

    # No more symlinks to jre
    if [ "X$MATLAB_JAVA" = "X" ]; then
    MATLAB_JAVA_CFG=`head -n 1 "${DEFAULT_JRE_LOC}.cfg" 2>/dev/null`
    else
    MATLAB_JAVA_CFG=$MATLAB_JAVA
    fi
    JRE_LOC=$DEFAULT_JRE_LOC${MATLAB_JAVA_CFG:-}
    if [ ! -d "$JRE_LOC" ]; then
    JRE_LOC=$MATLAB_JAVA_CFG
    fi
#
# Threads
#
    case "$ARCH" in
       *)
            JLIB=lib
            ;;
    esac
    JAVA_VM_PATH="$JRE_LOC/$JLIB/$JARCH/native_threads"
#
# JVM
#
    JVM_LIB_ARCH="$JRE_LOC/$JLIB/$JARCH"
    if [ "$ARCH" = "glnxa64" -o "$ARCH" = "maca64" -o "$ARCH" = "maci64" ]; then
        VM_FLAVOR=server
    else
        VM_FLAVOR=client
    fi
    if [ -d "$JVM_LIB_ARCH/$VM_FLAVOR" ]; then
    JAVA_VM_PATH="$JAVA_VM_PATH:$JVM_LIB_ARCH/$VM_FLAVOR"
    elif [ -d "$JVM_LIB_ARCH/hotspot" ]; then
    JAVA_VM_PATH="$JAVA_VM_PATH:$JVM_LIB_ARCH/hotspot"
    elif [ -d "$JVM_LIB_ARCH/classic" ]; then
    JAVA_VM_PATH="$JAVA_VM_PATH:$JVM_LIB_ARCH/classic"
    _JVM_THREADS_TYPE=native_threads; export _JVM_THREADS_TYPE
    fi

    if [ "$ARCH" = "maca64" -o "$ARCH" = "maci64" ]; then
        JAVA_VM_PATH="$JAVA_VM_PATH:$JVM_LIB_ARCH/$JLIB/jli"
    fi

#
# Augment with AWT Motif default locale resource files
#
    XFILESEARCHPATH="$JRE_LOC/lib/locale/%L/%T/%N%S:$XFILESEARCHPATH"
    export XFILESEARCHPATH
#
# Initialize LDPATH_MATLAB to include any VARIANT directory
#
    if [ "$VARIANT" != "" ]; then
        BIN_DIRS=$MATLAB/bin/$ARCH/$VARIANT:$MATLAB/bin/$ARCH
    else
        BIN_DIRS=$MATLAB/bin/$ARCH
    fi

    LDPATH_MATLAB=$MATLAB/sys/os/$ARCH:$BIN_DIRS:$MATLAB/extern/lib/$ARCH:$MATLAB/cefclient/sys/os/$ARCH

#
# If directory runtime/$ARCH exists add to LD_LIBRARY_PATH.  Needed for
# compiler and related builders.
#
    if [ -d "$MATLAB/runtime/$ARCH" ]; then
        LDPATH_MATLAB=$LDPATH_MATLAB:$MATLAB/runtime/$ARCH
    fi

#
# Determine whether to use hardware or software OpenGL
# Exit codes:
# 0: Hardware OpenGL, no warning
# 1: Hardware OpenGL, warning
# 2: Software OpenGL, no warning
# 3: Software OpenGL, warning
# 4: Incorrect values for internal variables
# 5: Incorrect number of arguments
#
$MATLAB/bin/matlab-glselector.sh "$nodisplay" "$noopengl" "$batchflag" "$usemesa" "$nousemesa" "$display" "$ARCH" "$MATLAB" 2>/dev/null
glselector=$?
if [ "$glselector" -eq "2" -o "$glselector" -eq "3" -o "$workerflag" -eq "1" ]; then
    # we select software OpenGL by changing the LD_LIBRARY_PATH
    LDPATH_MATLAB=$MATLAB/sys/opengl/lib/$ARCH:$LDPATH_MATLAB
fi
if [ "$workerflag" -eq "0" ]; then
    if [ "$glselector" -eq "1" -o "$glselector" -eq "3" ]; then
        # MATLAB will print the warning if the -prefersoftwareopengl
        # startup option is present.
        arglist="$arglist -prefersoftwareopengl"
    fi
fi

#
#-------------------------------------------------------------------------
#
# Determine the osg library path
#
# Note: Must come before LD_LIBRARY_PATH so MAC can add it to it library path
# as it does not support RPATH yet.

    osg="$MATLAB/sys/openscenegraph/lib/$ARCH"

    OSG_LD_LIBRARY_PATH=$osg
    export OSG_LD_LIBRARY_PATH

#
#--------------------------------------------------------------------------
#
# Determine <final_load_library_path> for each platform
#
    case "$ARCH" in
    glnx*)
        LD_LIBRARY_PATH="`eval echo $LD_LIBRARY_PATH`"
        LDPATH_MATLAB=$LDPATH_MATLAB:$JAVA_VM_PATH
        if [ "$LD_LIBRARY_PATH" != "" ]; then
        LD_LIBRARY_PATH=$LDPATH_MATLAB:$LD_LIBRARY_PATH
                LD_LIB_PATHmode="$rcfilep"
        else
        LD_LIBRARY_PATH=$LDPATH_MATLAB
                LD_LIB_PATHmode="$script"
        fi
        if [ "$LDPATH_PREFIX" != "" ]; then
            LDPATH_PREFIX="`eval echo $LDPATH_PREFIX`"
            if [ "$LDPATH_PREFIX" != "" ]; then
                    LD_LIBRARY_PATH=$LDPATH_PREFIX:$LD_LIBRARY_PATH
                    LD_LIB_PATHmode="$rcfilep"
        fi
        fi
        if [ "$LDPATH_SUFFIX" != "" ]; then
            LDPATH_SUFFIX="`eval echo $LDPATH_SUFFIX`"
            if [ "$LDPATH_SUFFIX" != "" ]; then
                    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LDPATH_SUFFIX
                    LD_LIB_PATHmode="$rcfilep"
        fi
        fi
            # Fix for Sun BugID 4663077
            if [ "`uname -r`" = "5.8" ]; then
                LD_LIBRARY_PATH=/usr/lib/lwp:$LD_LIBRARY_PATH
            fi

        export LD_LIBRARY_PATH
        ;;
    mac*)
        # DYLD_BIND_AT_LAUNCH=1
            # export DYLD_BIND_AT_LAUNCH
        DYLD_LIBRARY_PATH="`eval echo $DYLD_LIBRARY_PATH`"
        LDPATH_MATLAB=$LDPATH_MATLAB:$JAVA_VM_PATH
        if [ "$DYLD_LIBRARY_PATH" != "" ]; then
        DYLD_LIBRARY_PATH=$LDPATH_MATLAB:$DYLD_LIBRARY_PATH
                LD_LIB_PATHmode="$rcfilep"
        else
        DYLD_LIBRARY_PATH=$LDPATH_MATLAB
                LD_LIB_PATHmode="$script"
        fi
        DYLD_FRAMEWORK_PATH="`eval echo $DYLD_FRAMEWORK_PATH`"
        if [ "$DYLD_FRAMEWORK_PATH" != "" ]; then
        DYLD_FRAMEWORK_PATH=$LDPATH_MATLAB:$DYLD_FRAMEWORK_PATH
        else
        DYLD_FRAMEWORK_PATH=$LDPATH_MATLAB
        fi
        if [ "$LDPATH_PREFIX" != "" ]; then
            LDPATH_PREFIX="`eval echo $LDPATH_PREFIX`"
            if [ "$LDPATH_PREFIX" != "" ]; then
                    DYLD_LIBRARY_PATH=$LDPATH_PREFIX:$DYLD_LIBRARY_PATH
                    LD_LIB_PATHmode="$rcfilep"
        fi
        fi
        if [ "$LDPATH_SUFFIX" != "" ]; then
            LDPATH_SUFFIX="`eval echo $LDPATH_SUFFIX`"
            if [ "$LDPATH_SUFFIX" != "" ]; then
                    DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$LDPATH_SUFFIX
                    LD_LIB_PATHmode="$rcfilep"
        fi
        fi
        if [ -d "$osg" ]; then
         DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$osg
        fi
        if [ "$SOURCE_MATLAB_ENV_FROM" != "" ]; then
        export DYLD_LIBRARY_PATH
        export DYLD_FRAMEWORK_PATH
        fi
            export AWT_TOOLKIT=CToolkit
        ;;
    *)
        LD_LIBRARY_PATH="`eval echo $LD_LIBRARY_PATH`"
        LDPATH_MATLAB=$LDPATH_MATLAB
        if [ "$LD_LIBRARY_PATH" != "" ]; then
        LD_LIBRARY_PATH=$LDPATH_MATLAB:$LD_LIBRARY_PATH
                LD_LIB_PATHmode="$rcfilep"
        else
        LD_LIBRARY_PATH=$LDPATH_MATLAB
                LD_LIB_PATHmode="$script"
        fi
        if [ "$LDPATH_PREFIX" != "" ]; then
            LDPATH_PREFIX="`eval echo $LDPATH_PREFIX`"
            if [ "$LDPATH_PREFIX" != "" ]; then
                    LD_LIBRARY_PATH=$LDPATH_PREFIX:$LD_LIBRARY_PATH
                    LD_LIB_PATHmode="$rcfilep"
        fi
        fi
        if [ "$LDPATH_SUFFIX" != "" ]; then
            LDPATH_SUFFIX="`eval echo $LDPATH_SUFFIX`"
            if [ "$LDPATH_SUFFIX" != "" ]; then
                    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$LDPATH_SUFFIX
                    LD_LIB_PATHmode="$rcfilep"
        fi
        fi
        export LD_LIBRARY_PATH
        ;;
    esac

#--------------------------------------------------------------------------
#
# Warn against having set LD_ASSUME_KERNEL
#
    if [ "$ARCH" = "glnxa64" ] && \
       [ "$LD_ASSUME_KERNEL" != "" ]; then
        echo "----------------------------------------------------------------------------"
        echo "Warning: Environmental variable LD_ASSUME_KERNEL is currently set."
        echo " "
        echo "  LD_ASSUME_KERNEL=$LD_ASSUME_KERNEL"
        echo " "
        echo "MATLAB is not expected to perform properly when this variable has been set."
        echo "----------------------------------------------------------------------------"
        echo " "
    fi
#
#--------------------------------------------------------------------------
#
# SHELL must currently be defined.
#
    if [ "$SHELL" = "" ]; then
        SHELLmode="$script"
    SHELL="/bin/bash"
    fi
#
#--------------------------------------------------------------------------
#
#
#
    BASEMATLABPATH=$MATLABPATH; export BASEMATLABPATH
#
#--------------------------------------------------------------------------
#
# Add on $HOME/matlab if available
#

    if [ -d "$HOME"/matlab ]; then
    MATLABPATH=$MATLABPATH:"$HOME"/matlab
    fi

#
# Remove any leading ":" character from the path. Can't use awk
# here because it fails on very long paths.
#
    MATLABPATH=`echo "$MATLABPATH" | sed 's/^://'`
#
#--------------------------------------------------------------------------
#
# Check OS version
#
    if [ -f "$MATLAB_UTIL_DIR/oscheck.sh" ]; then
    . "$MATLAB_UTIL_DIR/oscheck.sh"
    if [ "$oscheck_status" = "1" ]; then
        exit 1
    fi
    fi
#
#--------------------------------------------------------------------------
#
# Set a floor on the maximum number of file descriptors that can be opened.
# The user can always set something higher before calling MATLAB.
#
    FLOOR_OPEN_FILES=1024
    MAX_OPEN_FILES=`ulimit -S -n`
    MAX_OPEN_FILESmode='e '
    if [ $MAX_OPEN_FILES -lt $FLOOR_OPEN_FILES ]; then
        ulimit -S -n $FLOOR_OPEN_FILES 2>/dev/null
        if [ $? -eq 0 ]; then
            MAX_OPEN_FILESmode='s '
            MAX_OPEN_FILES=`ulimit -S -n`
        fi
    fi
#
#--------------------------------------------------------------------------
#
    if [ "$showenv" = "1" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    (
    undefined='(variable not defined)'
    echo '------------------------------------------------------------------------'
    if [ "$SOURCED_DIR" != "" ]; then
    echo "->      (.matlab7rc.sh) sourced from directory (DIR = $SOURCED_DIR)"
    echo "->      DIR = $SOURCED_DIReval"
    else
    echo "->      (.matlab7rc.sh) not found."
    fi
    echo '------------------------------------------------------------------------'
    echo '        a = argument  e = environment  r = rcfile  s = script'
    echo '------------------------------------------------------------------------'
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo "->  $MATLABmode  MATLAB              = $MATLAB"
    echo "->      LM_LICENSE_FILE     = ${LM_LICENSE_FILE-$undefined}"
    echo "->      MLM_LICENSE_FILE    = ${MLM_LICENSE_FILE-$undefined}"
    echo "->  $AUTOMOUNT_MAPmode  AUTOMOUNT_MAP       = $AUTOMOUNT_MAP"
    echo "->  $DISPLAYmode  DISPLAY             = $DISPLAY"
    echo "->  $ARCHmode  ARCH                = $ARCH"
    echo "->  $TOOLBOXmode  TOOLBOX             = $TOOLBOX"
#
# For maximum number of open file descriptors
#
    echo "->  $MAX_OPEN_FILESmode  MAX_OPEN_FILES      = $MAX_OPEN_FILES"
#
# For java
#
    echo "->  s   _JVM_THREADS_TYPE   = $_JVM_THREADS_TYPE"
    echo "->  e   MATLAB_JAVA         = $MATLAB_JAVA"
#
    echo "->  $MATLAB_MEM_MGRmode  MATLAB_MEM_MGR      = $MATLAB_MEM_MGR"
    echo "->  $MATLAB_DEBUGmode  MATLAB_DEBUG        = $MATLAB_DEBUG"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    case "$ARCH" in
        mac*)
    echo "->  $LD_LIB_PATHmode  DYLD_LIBRARY_PATH   = $DYLD_LIBRARY_PATH"
        ;;
        *)
    echo "->  $LD_LIB_PATHmode  LD_LIBRARY_PATH     = $LD_LIBRARY_PATH"
        ;;
    esac
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo "->  $argument  arglist             = $arglist"
    echo "->  $SHELLmode  SHELL               = $SHELL"
    echo "->  e   PATH                = $PATH"
    echo " "                                    ) > "$temp_file"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fi
#
# Cannot locate JRE
#
    if [ ! -d "$JRE_LOC" -a "$jvmflag" = "1" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(
echo "---------------------------------------------------------------------------"
echo "Warning: Cannot locate Java Runtime Environment (JRE) . . ."
echo " "
echo "         1. Either a correct JRE was not available for redistribution when"
echo "            this release was shipped, in which case you should refer to the"
echo "            Release Notes for additional information about how to get it."
echo " "
echo "         2. Or you have tried to use the MATLAB_JAVA environment variable"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    if [ "$showenv" != "1" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo "            to specify an alternate JRE, but MATLAB cannot find it.  Please"
echo "            run 'matlab -n' to determine what value you are using for"
echo "            MATLAB_JAVA and fix accordingly."
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    else
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo "            to specify an alternate JRE, but MATLAB cannot find it.  Check"
echo "            the value of MATLAB_JAVA above and fix accordingly."
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fi
echo "---------------------------------------------------------------------------" ) >> "$temp_file"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    if [ "$showenv" != "1" ]; then
        cat "$temp_file"
        rm -f "$temp_file"
    else
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo " "                                    >> "$temp_file"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fi
    fi
#
    if [ "$showenv" = "1" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(
    echo "->  $MATLABPATHmode  MATLABPATH          = (initial version)"
    if [ "$MATLABPATH" != "" ]; then
        for dir in `echo $MATLABPATH | tr ':' ' '`
        do
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo "  $dir"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        done
    fi
#
    echo " "
        if [ -f "$MATLAB/bin/$ARCH/$VARIANTmatlab" -a -f "$MATLAB/bin/ldd" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo '->      $MATLAB/bin/'"$ARCH/$VARIANTmatlab shared library information -"
    echo "|-----------------------------------------------------------------------"
            "$MATLAB/bin/ldd" -$ARCH "$MATLAB/bin/$ARCH/$VARIANTmatlab" 2>/dev/null | awk '{ print "| " $0 }'
    echo "|-----------------------------------------------------------------------"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        fi
#
    echo " "
    echo '->      $MATLAB/toolbox/local/pathdef.m -'
    echo "|-----------------------------------------------------------------------"
    if [ -f "$MATLAB/toolbox/local/pathdef.m" ]; then
        cat "$MATLAB/toolbox/local/pathdef.m" | awk '{ print "| " $0 }'
    else
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo '    Warning: $MATLAB/toolbox/local/pathdef.m not found . . .'
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fi
    echo "|-----------------------------------------------------------------------"
#
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo '------------------------------------------------------------------------') >> "$temp_file"
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    more "$temp_file"
        rm -f "$temp_file"
    if [ "$showenv_all" != "1" ]; then
         exit 0
    fi
    fi
#
# Export the variables
#
    export MATLAB
    export AUTOMOUNT_MAP
    export DISPLAY
    export ARCH
    export TOOLBOX
    export MATLABPATH
    export MATLAB_MEM_MGR
    export MATLAB_DEBUG
    export SHELL

#
# Start MATLAB unless we were asked to simply set the environment
#
    if [ "$SOURCE_MATLAB_ENV_FROM" = "" ]; then

    if [ ! -d "$MATLAB/bin/$ARCH" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo ''
    echo '    matlab: No MATLAB bin directory for this machine architecture.'
    echo ''
    echo "           ARCH = $ARCH"
    echo ''
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        if [ "$showenv_all" = "1" ]; then
        env
        fi
            exit 1
    fi
#
    if [ ! -f "$MATLAB/bin/$ARCH/$VARIANTmatlab" ]; then
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    echo ''
    echo "  matlab: No MATLAB executable for this machine architecture."
    echo ''
    echo "           $MATLAB/bin/$ARCH/$VARIANTmatlab does not exist!"
    echo ''
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        if [ "$showenv_all" = "1" ]; then
        env
        fi
            exit 1
    fi
#
    exec_path=$MATLAB/bin/$ARCH/$VARIANTmatlab
    
    # Preload glibc_shim in case of RHLE7 variants
    test -e /usr/bin/ldd &&  ldd --version |  grep -q "(GNU libc) 2\.17"  \
            && LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$MATLAB/bin/glnxa64/glibc-2.17_shim.so" \
            && export MW_GLIBC_SHIM="$MATLAB/bin/glnxa64/glibc-2.17_shim.so"

    export PRE_LD_PRELOAD="$LD_PRELOAD"

    # Do not accept any accidentally/maliciously set user-defined values
    MW_LD_SHIM=""
    MW_PATCH_OFFSETS=""
    if [ "$DISABLE_LD_PATCH" = "" -o "$DISABLE_LD_PATCH" = "0" ]; then
        LD_PATCH_ROOT="$MATLAB/bin/glnxa64"

        case `test -e /usr/bin/ldd &&  ldd --version | grep 'ldd'` in
            *"Debian GLIBC 2.28"*) # Debian 10, glibc 2.28
                LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$LD_PATCH_ROOT/ld_shim.so.2.28"
                export MW_LD_SHIM="$LD_PATCH_ROOT/ld_shim.so.2.28"
                export MW_PATCH_OFFSETS=00000EA000000040
                ;;
            *"Ubuntu GLIBC 2.27"*) # Ubuntu 18.04 LTS, glibc 2.27
                LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$LD_PATCH_ROOT/ld_shim.so.2.27"
                export MW_LD_SHIM="$LD_PATCH_ROOT/ld_shim.so.2.27"
                export MW_PATCH_OFFSETS=00001520000006B0
                ;;
            *"Ubuntu GLIBC 2.31"*) # Ubuntu 20.04 LTS, glibc 2.31
                LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$LD_PATCH_ROOT/ld_shim.so.2.31"
                export MW_LD_SHIM="$LD_PATCH_ROOT/ld_shim.so.2.31"
                export MW_PATCH_OFFSETS=0000104000000050
                ;;
            *"(GNU libc) 2.17"*) # RedHat 7, glibc 2.17
                LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}$LD_PATCH_ROOT/ld_shim.so.2.17"
                export MW_LD_SHIM="$LD_PATCH_ROOT/ld_shim.so.2.17"
                export MW_PATCH_OFFSETS=00001080000008F0
                ;;
        esac

        if [ "$LD_SHIM_DIAG" = "1" -a "$MW_PATCH_OFFSETS" != "" ]; then
            echo MW_PATCH_OFFSETS="$MW_PATCH_OFFSETS"
            echo LD_PRELOAD="$LD_PRELOAD"
        fi
    fi

    if [ "$LD_PRELOAD" != "" ]; then
        export LD_PRELOAD
    fi
#
        if [ "$debugger" != "" ]; then
            if [ "$MATLAB_DEBUG" = "gdb" -o "$MATLAB_DEBUG" = "xxgdb" \
                -o "$MATLAB_DEBUG" = "undodb-gdb" -o "$MATLAB_DEBUG" = "ddd" -o "$MATLAB_DEBUG" = "udb" ]; then

                if [ "$MW_GDBINIT" != "" -a -f "$MW_GDBINIT" ]; then
                    debugger="$debugger -ix $MW_GDBINIT"
                fi

                debugger="$debugger --args" # Enable GDB to accept program arguments
                SHELL=/bin/sh; export SHELL
            elif [ "$MATLAB_DEBUG" = "lldb" ]; then
                if [ "$MW_CUSTOM_DEVELOPER_DIR" != "" ]; then
                    debugger="$MW_CUSTOM_DEVELOPER_DIR/usr/bin/lldb"
                else
                    debugger="xcrun lldb"
                fi

                debugger="$debugger --" # Enable LLDB to accept program arguments

                # Source a shell script to set up the LLDB debug environment if needed
                if [ "$MW_LLDB_DEBUG_SETUP_SH" != "" -a -f "$MW_LLDB_DEBUG_SETUP_SH" ]; then
                    . "$MW_LLDB_DEBUG_SETUP_SH"
                fi
            fi
        elif [ "$timingWanted" != "" ]; then
            if [ \( "$MATLAB_CPUCOUNT" != "" \) -a  \( -f "$MATLAB/bin/$ARCH/cpucount" \) ]; then
                cpucount=`"$MATLAB/bin/$ARCH/cpucount"`
                arglist="$arglist -timing $MATLAB_CPUCOUNT $cpucount"
            else
                arglist="$arglist -timing"
            fi
        fi

        # Special configuration for the memory manager.
        # The memory manager is not configurable if the script is missing.
        memcheck_path=$MATLAB/bin/$ARCH/memcheck
        if [ ! -f "$memcheck_path" ]; then
            unset MATLAB_MEM_MGR
            unset memcheck_path
        fi

        if [ "$showenv_all" = "1" ]; then
            env
            exit 0
        elif [ "$MWE_INSTALL" != "" ]; then
            echo "Information enclosed between the next two dashed lines is for internal use only!"
            echo "-------------------------------------------------------------------"
            # Source a shell script to set up a debug environment if provided
            if [ "$MW_DEBUG_SETUP_SH" != "" -a -f "$MW_DEBUG_SETUP_SH" ]; then
                . "$MW_DEBUG_SETUP_SH"
            fi
            echo Launching MATLAB_MEM_MGR=\"$MATLAB_MEM_MGR\" $debugger $exec_path $arglist [PID = $$]
            echo "-------------------------------------------------------------------"
        fi

        # This must be the last thing we do before launching MATLAB,
        # otherwise we may affect anything spawned from this script.
        if [ "$memcheck_path" != "" ]; then
            . "$memcheck_path"
        fi

        eval exec "$debugger \"$exec_path\" $arglist"
    fi
