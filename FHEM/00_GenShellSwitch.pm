################################################################
#
#  Copyright notice
#
#  (c) 2013 NICK-ST
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  This copyright notice MUST APPEAR in all copies of the script!
#
################################################################

# derived from 23_ALL4027.pm, dummy.pm

package main;

use strict;
use warnings;

###################################
sub
GenShellSwitch_Initialize($)
{
  my ($hash) = @_;

  $hash->{SetFn}     = "GenShellSwitch_Set";
  $hash->{DefFn}     = "GenShellSwitch_Define";
  $hash->{AttrList}  = "loglevel:0,1,2,3,4,5,6 ". $readingFnAttributes;
}

###################################
sub
GenShellSwitch_Set($@)
{
  my ($hash, @a) = @_;

  return "no set value specified" if(int(@a) < 2);
  return "Unknown argument $a[1], choose one of on off toggle on-for-timer" if($a[1] eq "?");

  my $v = $a[1];
  my $v2= "";
  if(defined($a[2])) { $v2=$a[2]; }

  if($v eq "toggle")
  {
    if(defined $hash->{READINGS}{state}{VAL})
    {
      if($hash->{READINGS}{state}{VAL} eq "off")
      {
        $v="on";
      }
      else
      {
        $v="off";
      }
    }
    else
    {
      $v="off";
    }
  }
  elsif($v eq "on-for-timer")
  {
    InternalTimer(gettimeofday()+$v2, "GenShellSwitch_on_timeout",$hash, 0);
    # on-for-timer is now a on.
    $v="on";
  }
  GenShellSwitch_execute($hash,$v);

  Log GetLogLevel($a[0],2), "GenShellSwitch set @a";

  $hash->{CHANGED}[0] = $v;
  $hash->{STATE} = $v;
  $hash->{READINGS}{state}{TIME} = TimeNow();
  $hash->{READINGS}{state}{VAL} = $v;

  DoTrigger($hash->{NAME}, undef);

  return undef;
}

###################################
sub 
GenShellSwitch_on_timeout($)
{
  my ($hash) = @_;
  my @a;

  $a[0]=$hash->{NAME};
  $a[1]="off"; 

  GenShellSwitch_Set($hash,@a);

  return undef;
}

###################################
sub
GenShellSwitch_execute($@)
{
	my ($hash, $cmd) = @_;
  my $command=$hash->{Command};
  
  if($cmd eq "on")
  {
    $command.=$hash->{OnValue}." |";
  }
  elsif($cmd eq "off")
  {
    $command.=$hash->{OffValue}." |";
  }
  else
  {
    return undef;
  }

	Log GetLogLevel($hash->{NAME},4), "GenShellSwitch command line: $command";
  open(DATA,$command);
  while ( defined( my $line = <DATA> )  ) 
  {
    chomp($line);
    Log GetLogLevel($hash->{NAME},3), "GenShellSwitch command result: $line";
  }
  close DATA;
  
  #little sleep to avoid continous activities; controller might not like this
  sleep 0.25;

  return undef;
}

###################################
sub
GenShellSwitch_Define($$)
{
  my ($hash, $def) = @_;
  my $name=$hash->{NAME};

  my @a = split("[ \t][ \t]*", $def);  
  return "Wrong syntax: use define <name> GenShellSwitch <send command e.g. /home/pi/GenShellSwitch-pi/send a 1 1> <on value e.g. 1> <off value e.g. 0>" if(int(@a) < 5);
  
  my $command;
  my $max = int(@a)-2;
  for (my $i=2;$i<$max;$i+=1)
  {
    $command.=$a[$i]." ";
  }
  my $onvalue = $a[int(@a)-2];
	my $offvalue = $a[int(@a)-1];
  
  $hash->{Command} = $command;
  $hash->{OnValue} = $onvalue;
  $hash->{OffValue} = $offvalue;
 
  return undef;
}

1;

=pod
=begin html

<a name="GenShellSwitch"></a>
<h3>GenShellSwitch</h3>
<ul>
  Note: Take care that commands can be executed with fhem's user rights.
  <br><br>
  <a name="GenShellSwitch"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; GenShellSwitch &lt;command&gt &lt;on value&gt &lt;off value&gt;</code>
    <br><br>
    Defines a generic switch that executes a command line. This can be e.g. used to integrate rcswitch. &lt;command&gt may contain spaces. Command is executed followed by the on/off value.<br><br>


    Examples:
    <ul>
      <code>define lamp1 RCSwitch /home/pi/rcswitch-pi/send a 1 1 1 0</code><br>
    </ul>
  </ul>
  <br>

  <a name="GenShellSwitchset"></a>
  <b>Set </b>
  <ul>
    <code>set &lt;name&gt; &lt;value&gt;</code>
    <br><br>
    where <code>value</code> is one of:<br>
    <pre>
    off
    on
    on-for-timer &lt;Seconds&gt;
    toggle
    </pre>
    Examples:
    <ul>
      <code>set lamp1 on</code><br>
    </ul>
    <br>
    Notes:
    <ul>
      <li>Toggle is special implemented. List name returns "on" or "off" even after a toggle command</li>
    </ul>
  </ul>
</ul>

=end html
=cut
