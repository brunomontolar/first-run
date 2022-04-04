# First Run

I created this bash script to make easier the process of setting up a new machine.

It has the basic and the full type of installation:  

- The basic focus on setting up my Raspberry, which I use to host some of my services. 

- Full installation has additional applications that I use in my main computer.

### Running the script
To use script run these commands:

``` 
chmod +x ./first-run-installer.sh
```
Then 
```
sudo ./first-run-installer.sh
```
#### Passing parameters
It's possible to pass two parameters when running the executable:
- To run the full installation:
```
-f
```

- To specify the name of your ssh key file:
```
-k "filename"
```

---
### Custom SSH Key name
This script will create an ssh key named **id_bmont**, but if you want to change to another you can pass the parameter above or change the following line in the script:

```
SSHKEYNAME=filename
```
---

### Using Wireguard
Add the wireguard configuration to file at:

```
/etc/wireguard/wg0.conf
```

Start Wireguard connection with the following command: 

```
sudo sudo wg-quick up wg0
```

Close connection with:

```
sudo wg-quick down wg0
```

---
## The script will install:
### Basic Installation:
- Python 3
- Pip
- Git
- Curl
- Vim
- SSH Server
- Docker
- Docker Compose
- Portainer
- Add SSH config for GitHub
- Create SSH Keys for machine
 
### Full installation:
### The packages above and these additional:
- VS Code
- Arduino
- Nmap
- Open VPN
- Wireguard
- Terminator
- Meslo Font
- Zsh
- OhMyZsh
- Powerlevel10k
