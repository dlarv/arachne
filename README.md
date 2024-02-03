## Arachne-Nav
Utils for navigating around command line.

## Arachne-Find
Wrapper for find command. Searches entire system while ignoring directories specified in $MYTHOS_CONFIG_DIR/arachne/find.conf.

## Arachne-Info
Wrapper for du command.

## Arachne-Term
Opens a context aware terminal.

Consists of 2 parts: 
- arachne-launcher: WM and terminal specific. Finds the name and PID of the currently active window, which it passes to arachne-term. It then opens an instance of Arachne.
- arachne-term: Parses commands from the config file to determine which working directory Arachne should be opened in.
