####################################################################
#
# This function returns a list of logical drives in Windows.
# Each list element starts with drive letter, followed by
# drive type, serial number, file system, label, total space
# and free space. All items will be separated by a '*' character.
#
# If one or more letters are provided as an argument,
# then data will be returned only about those drives.
# Example:
#   GetDriveInfo('CE') => Returns data about drive C: and E:
# If drive E: does not exist, then it will be left
# out of the list!
#
# Usage: STRING = GetDriveInfo([DRIVEs])
#
sub GetDriveInfoJS
{
  my $DRIVES = defined $_[0] ? $_[0] : 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  print "\nJS Gets:\n";
  return RunJS("V='$DRIVES';try{FSO=new ActiveXObject('Scripting.FileSystemObject');}catch(e){WScript.Quit(0);}A=[];function ToHex(N){N|=0;var i,X='';for(i=0;i<32;i+=4)X='0123456789ABCDEF'.charAt((N>>i)&15)+X;return X;}for(i=0;i<V.length;i++){L=V.charAt(i)+':';if(FSO.DriveExists(L)){D=FSO.GetDrive(L);if(D.IsReady){S=ToHex(D.SerialNumber)+'*'+D.FileSystem+'*'+D.VolumeName+'*'+D.TotalSize+'*'+D.FreeSpace;}A.push(L+'*'+D.DriveType+'*'+S);}}WScript.StdOut.WriteLine(A.join(\"\\r\\n\"));");

=begin FormattedJS

V='$DRIVES';
try{
    FSO=new ActiveXObject('Scripting.FileSystemObject');
}
catch(e){
    WScript.Quit(0);
}
A=[];
function ToHex(N){
    N|=0;
    var i,X='';
    for(i=0;i<32;i+=4)
        X='0123456789ABCDEF'.charAt((N>>i)&15)+X;
    return X;
}
for(i=0;i<V.length;i++){
    L=V.charAt(i)+':';
    if(FSO.DriveExists(L)){
        D=FSO.GetDrive(L);
        if(D.IsReady){
            S=ToHex(D.SerialNumber)+'*'+D.FileSystem+'*'+D.VolumeName+'*'+D.TotalSize+'*'+D.FreeSpace;
        }
        A.push(L+'*'+D.DriveType+'*'+S);
    }
}
WScript.StdOut.WriteLine(A.join("\\r\\n"));

=cut

}


#
# Usage: INTEGER = RunJS(JSCODE)
#
sub RunJS
{
  no warnings;
  $^O =~ m/MSWIN/i && defined $_[0] && length($_[0]) or return 0;
  mkdir "C:\\TEMP";
  my $TEMPFILE = "C:\\TEMP\\JSTMP001.JS";
  my $CSCRIPT = "C:\\WINDOWS\\SYSTEM32\\CSCRIPT.EXE";
  -f $CSCRIPT or return 0;
  local *FILE;
  open(FILE, ">$TEMPFILE") or return 0;
  binmode FILE;
  print FILE $_[0];
  close FILE;
  -f $TEMPFILE && -s $TEMPFILE == length($_[0]) or return 0;
  my $E = system("$CSCRIPT //NOLOGO $TEMPFILE");
  unlink $TEMPFILE;
  return $E + 1;
}

# in response to [id://11165216]
# Recreate the JS in actual Perl with Win32-based modules, because there's no reason to spawn a javascript interpreter to run a ScriptingObject library to do the underlying win32 api calls that they wrap
use warnings;
use strict;
use Win32API::File ();          # comes pre-installed with Strawberry Perl
use Win32::DriveInfo ();        # installed using `cpanm Win32::DriveInfo`
sub GetDriveInfoPL
{
    my $drives = defined $_[0] ? $_[0] : join('', 'A'..'Z');
    local $\ = "\n";
    my $retval = "\nPerl Gets:\n";
    for ( split //, $drives ) {
        my $drive = $_ . ':';

        # GetDriveType is one of many ways to determine whether it's an active drive or not, with the benefit that it can distinguish between types of drives
        my $type = Win32API::File::GetDriveType($drive);
        next unless $type > Win32API::File::DRIVE_NO_ROOT_DIR;
        my $typestr = (qw/DRIVE_UNKNOWN DRIVE_NO_ROOT_DIR DRIVE_REMOVABLE DRIVE_FIXED DRIVE_REMOTE DRIVE_CDROM DRIVE_RAMDISK/)[$type];
        #print "GetDriveType($drive) = $type => $typestr";
        my $fsotype = $type - 1; # the FSO .DriveType is off-by-one from the Win32API::File::GetDriveType() call: <https://learn.microsoft.com/en-us/office/vba/language/reference/user-interface-help/drivetype-property>

        # GetVolumeInformation grabs most of the attributes available from the FSO Drive object properties
        warn "GetVolumeInformation($drive) failed: $^E\n" unless Win32API::File::GetVolumeInformation("${drive}/", my $osVolName, 99, my $ouSerialNum, my $ouMaxNameLen, my $ouFsFlags, my $osFsType, 99 );
        my $hexSerialNum = sprintf '%X', $ouSerialNum;
        #print "GetVolumeInformation(${drive}/) => $osVolName, $ouSerialNum = 0x$hexSerialNum, $ouMaxNameLen, $ouFsFlgs, $osFsType";

        #... except size info, which can be gotten through Win32::DriveInfo
        my @space = Win32::DriveInfo::DriveSpace($drive);
        #print "DriveSpace($drive) = ", join ', ', @space;

        $retval .= "$drive*$fsotype*$hexSerialNum*$osFsType*$osVolName*$space[5]*$space[6]\n";
    }
    print $retval;
}

GetDriveInfoJS();
GetDriveInfoPL();
