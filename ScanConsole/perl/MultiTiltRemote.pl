#!/usr/bin/env perl
#
# Run batch file in Windows command terminal
# MultiTiltRemote dicomfolder angle.txt
#
use strict; use warnings; use v5.38;

my $SERVER="moonc@10.48.88.13";
my $ID_FILE="gyrus2";
my $REMOTE_SYNC="~/sshremote/BOLDSliceAngle";

my $dcmfolder=$ARGV[1];
my $anglefile=$ARGV[2];
my $rslcdcmfolder="Reslice_${dcmfolder}";

system("echo scp -rpi ${ID_FILE} ${dcmfolder} ${anglefile} ${SERVER}:${REMOTE_SYNC}/");
system("echo ssh -i ${ID_FILE} ${SERVER} '~/data/BOLDSliceAngle/FmapCorrect/proc_multitilt.bash ${REMOTE_SYNC}'");
system("echo scp -rpi ${ID_FILE} ${SERVER}:${REMOTE_SYNC}/${rslcdcmfolder} ./");

# cleanup on remote
#ssh -i gyrus2 %server% "cd ~/sshremote/BOLDSliceAngle; chmod -R 775 *; rm -rf %dcmfolder%; rm -rf %rslcdcmfolder%; rm %anglefile%; rm -rf Analyzer;" 
