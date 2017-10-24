# zmarbles

**NOTE:** The assumption is that you have already set up your Linux on IBM Z instance to support Hyperledger Fabric v1.0.0, v1.0.1, v1.0.2 or v1.0.3 and that you have already downloaded or created the Docker images for the release you wish to use, and that these images have the *latest* tag.

## Installation 

1. Navigate to a directory on a file system that has ample free disk space, e.g. 8 GB or more free.  If you have adequate free space on the file system that holds your *$HOME* directory, I recommend working from your *$HOME*,  e.g. `cd $HOME`. 
   **Note**: If you are on a LinuxONE Community Cloud instance, although your file system for your *$HOME* is small, the */data* file system is large and has plenty of space, so, e.g. `cd /data/linux1` would make sense here.  (Create */data/linux1* with `mkdir /data/linux1` if it does not already exist).

2. `git clone https://github.com/silliman/zmarbles.git`

3. `cd zmarbles`

## Running the application

Simply run `./zmarbles-setup.sh` from within your *zmarbles* directory.  Running this command with no arguments will display some brief help.

There are four positional arguments to the `./zmarbles-setup.sh` script.  The first argument is required and should be either `up` or `down` or `restart`.  This is to indicate what action you want to take against the zmarbles app (and the underlying Hyperledger Fabric network infrastructure that supports it).  **up** and **down** are self-explanatory and **restart** will attempt to bring down the network and reset things before bringing the network back up again.  

The second argument is the name of the channel to create.  It defaults to `mychannel`.  

The third argument is a positive integer that specifies the number of seconds that the **cli** Docker container will remain active after the completion of the Hyperledger Fabric cli commands that set up the Hyperledger Fabric network and the marbles chaincode.  The default is 10 seconds. A larger value could be specified for debugging purposes if something goes wrong, since it would be convenient to have the cli Docker container stay active. But in most cases the default value is sufficient.

The fourth argument specifies whether CouchDB will be used for the state database.  If this argument is not specified or is any value other than **couchdb** (lowercase), then CouchDB will not be used for the state database.  Instead, **levelDB**, which is the default database provider, will be used. 

**Note:** Since the arguments are positional, if you want to specify the third or fourth arguments, you will need to specify the preceding arguments even if you just wanted the defaults for them.

### Examples

`./zmarbles_setup.sh up`   # start with the default channel name of *mychannel* and do not use CouchDB

`./zmarbles_setup.sh up tim`  # start with a channel name of *tim* and do not use CouchDB

`./zmarbles_setup.sh up mychannel 10 couchdb`  # start with the default channel name of *mychannel* and use CouchDB

`./zmarbles_setup.sh up mychannel 3600` # start with the default name of *mychannel*, do not use CouchDB, and keep the *cli* Docker container alive for one hour (3600 seconds) which may be useful for debugging

`./zmarbles_setup.sh restart `  # shut down the marbles web app and the Hyperledger Fabric network (if they are running) and then start with the default channel name of *mychannel* and do not use CouchDB

`./zmarbles_setup.sh down mychannel 10 couchdb`  # shut down the marbles web app and the Hyperledger Fabric network.  

## Marbles Web App User Interface (UI)

Two instances of the Marbles Web App UI will start up about six minutes after the start of the execution of this script.  This is because there is a bug in Hyperledger Fabric where if a certificate is created, the Node.js SDK thinks it is invalid for about the first five minutes of that certificate's existence.  So as a workaround there is a 360-second delay after the certificates are created before the MarblesUI is started.  Once it is started, one instance of the app will be listening on port 3001 for the first organization in the Network, and a second instance of the app will be listening on port 3002 for the second organization in the network.  Point a browser tab to each of these two ports, i.e. `http://<your_hostname_or_IP>:3001` and `http://<your_hostname_or_IP>:3002`

## Troubleshooting

A one-time *npm install* is required to run the Marbles Web App User Interface. This is run for you if the script does not detect a *node_modules* directory in the *zmarbles/marblesUI* directory. Access to the public Internet is required by this *npm install* command. If your environment restricts access to the Internet, the *npm install* command may fail to retrieve everything it needs. In this case, a compressed tar file, **zmarblesNPM.tar.gz** is provided. Enter the `tar` command shown below in this case, from your *zmarbles* directory:

`tar --strip-components=1 -xzvf zmarblesNPM.tar.gz` 

This tar file contains the node_modules directory inside of the zmarbles/marblesUI directory, that is, the *npm install* has been done for you.  This file is recommended only if your system has restrictions that prevent the npm install command from running successfully. 
