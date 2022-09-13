
#a/usr/bin/perl
# This script was hastily cobbled together for my own use. It can
# probably break your system. Use at your own risk.

$JAIL = "/srv/http";
$USER = "http";
$GROUP = "http";
$WWW_DIR = "www";

sub run{
  # Only print the commands that will be executed until the user
  # manually decides to run them.
  print "$_[0]\n";
  #system($_[0]);
}

@dirs = ("etc/nginx/logs", "dev", "usr/{lib,sbin}", "usr/share/nginx",
  "tmp", "run", "var/{log,lib}/nginx", $WWW_DIR, "$WWW_DIR/cgi-bin");

foreach (@dirs) {
  run("mkdir -p $JAIL/$_");
}

run("mount -t tmpfs none $JAIL/run -o 'noexec,size=1M'");
run("mount -t tmpfs none $JAIL/tmp -o 'noexec,size=100M'");

run("cp -r /usr/share/nginx/* $JAIL/usr/share/nginx/");
run("cp -r /usr/share/nginx/html/* $JAIL/$WWW_DIR");

run("cp /usr/sbin/nginx $JAIL/usr/sbin/");

run("cp -r /var/lib/nginx $JAIL/var/lib/nginx");
run("cd $JAIL; ln -s usr/lib lib");


@devs = ("null c 1 3", "random c 1 8");
foreach (@devs) {
   run("/usr/bin/mknod -m 0666 $JAIL/dev/$_");
}
run("/usr/bin/mknod -m 0444 $JAIL/dev/urandom c 1 9");

@ldds = split("\n", `ldd /usr/sbin/nginx`);
foreach (@ldds) {
  if(m/((\/.*)?\/lib\/.*) \(0x/){
    run("cp $1 $JAIL$1");
  }
}

run("cp /usr/lib/libnss_* $JAIL/usr/lib/");

# 
# /etc{adjtime,hosts.deny} might also be needed.
run("cp -Lrfv /etc/{services,localtime,nsswitch.conf,nscd.conf,protocols,hosts,ld.so.cache,ld.so.conf,resolv.conf,host.conf,nginx} $JAIL/etc");

run("echo 'http:x:33:' > $JAIL/etc/group");
run("echo 'nobody:x:99:' >> $JAIL/etc/group");

run("echo 'http:x:33:33:http:/:/bin/false' > $JAIL/etc/passwd");
run("echo 'nobody:x:99:99:nobody:/:/bin/false' >> $JAIL/etc/passwd");

run("echo 'http:x:14871::::::' > $JAIL/etc/shadow");
run("echo 'nobody:x:14871::::::' >> $JAIL/etc/shadow");

run("echo 'http:::' > $JAIL/etc/gshadow");
run("echo 'nobody:::' >> $JAIL/etc/gshadow");

run("touch $JAIL/etc/shells");
run("touch $JAIL/run/nginx.pid");

run("chown -R root:root $JAIL/");

run("chown -R $USER:$GROUP $JAIL/$WWW_DIR");
run("chown -R $USER:$GROUP $JAIL/etc/nginx");
run("chown -R $USER:$GROUP $JAIL/var/{log,lib}/nginx");
run("chown $USER:$GROUP $JAIL/run/nginx.pid");
#run("chown -R $USER:$GROUP $JAIL/usr/sbin/nginx");

run("find $JAIL/ -gid 0 -uid 0 -type d -print | xargs chmod -rw"); 
run("find $JAIL/ -gid 0 -uid 0 -type d -print | xargs chmod +x");
#run("find $JAIL/ -gid 0 -uid 0 -type f -print | xargs chmod -x");
run("find $JAIL/etc -gid 0 -uid 0 -type f -print | xargs chmod -x");
#run("find $JAIL/usr/lib -gid 0 -uid 0 -type f -print | xargs chmod -x");
run("find $JAIL/usr/sbin -type f -print | xargs chmod ug+rx");
run("find $JAIL/ -gid 33 -uid 33 -print | xargs chmod o-rwx"); 
run("chmod +rw $JAIL/tmp");
run("chmod +rw $JAIL/run");

run("setcap 'cap_net_bind_service=+ep' $JAIL/usr/sbin/nginx");
