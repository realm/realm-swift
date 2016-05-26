To run the server  go to the server folder in your terminal and run the realm-server-noinst binary.
```
	realm-server-noinst realm_server_folder hostname -p port -l loglevel -k keyfile.pem

	Options:
	  -h, --help              Display command-line synopsis followed by the list of
	                          available options.
	  -p, --listen-port       The listening port. (default '7800')
	  -r, --no-reuse-address  Disables immediate reuse of listening port.
	  -l, --log-level         Set log level (0 for nothing, 1 for normal, 2 for
	                          everything).
	  -k, --key               The public key (PEM file) used to verify identity
	                          tokens sent by clients. Mandatory.
```


Example:
```
mkdir /tmp/server_folder
./realm-server-noinst /tmp/server_folder 127.0.0.1 -p 7800 -l 2 -k public.pem
```

Where 
	`/tmp/server_folder` is a directory you have created for server-side Realm files.

	`public.pem` is the public key included in the server folder. The demo app already contains tokens valid for this key.
    Use the ip your computer has in the local network instead of `127.0.0.1`.

If you want to start from scratch, you should stop the server, empty the directory for server-side Realm files and start the server again.
