#!/bin/bash

# Define colors...
RED=`tput bold && tput setaf 1`
GREEN=`tput bold && tput setaf 2`
YELLOW=`tput bold && tput setaf 3`
BLUE=`tput bold && tput setaf 4`
NC=`tput sgr0`

# Define variables
FULL_INSTALL=false
HOME_PATH=$(getent passwd $SUDO_USER | cut -d: -f6)
SSHPATH=$HOME_PATH/.ssh/
SSHKEYNAME=id_bmont
SSHGIT="#GITHUB\nHost github.com\n  HostName github.com\n  User git\n  IdentityFile $HOME_PATH/.ssh/$SSHKEYNAME"

function RED(){
	echo -e "\n${RED}${1}${NC}"
}
function GREEN(){
	echo -e "\n${GREEN}${1}${NC}"
}
function YELLOW(){
	echo -e "\n${YELLOW}${1}${NC}"
}
function BLUE(){
	echo -e "\n${BLUE}${1}${NC}"
}

#Check if is root
if [ $UID -ne 0 ] 
then
    RED "You must run as root" && echo
    exit 1
fi

while getopts ":hfk" option; do
    case $option in
        h) # display Help
            echo "User -f for full installation or -k to specify the filename for your ssh key"
            exit;;
        f) # Full Installation
            FULL_INSTALL=true;;
        k) #Name of ssh key
            SSHKEYNAME=$OPTARG;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

#Check if want full install
if !($FULL_INSTALL)
then
    read -r -p "Make full installation? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        FULL_INSTALL=true
    fi
fi

#Updating packages
BLUE "Updating Packages..."
sudo apt-get update 

BLUE "Installing Python3..."
sudo apt install -y python3

BLUE "Installing Pip3..."
sudo apt install -y python3-pip

BLUE "Installing Git..."
sudo apt install -y git

BLUE "Installing Vim..."
sudo apt install -y vim

BLUE "Installing Curl..."
sudo apt-get install -y curl

#Git Configuration
BLUE "Setting up Git Config"
if !(git config user.name)
then
    read -p "Insert Git username: " username
sudo -i -u $SUDO_USER bash << EOF
    git config --global user.name $username
EOF
else
    GREEN "Username is already set"
fi

if !(git config user.email)
then
    read -p "Insert Git email: " email
sudo -i -u $SUDO_USER bash << EOF
    git config --global user.email $email
EOF
else
    GREEN "Email Username is already set"
fi

#SSH Server
BLUE "Installing SSH..."
if ! command -v ssh &> /dev/null
then
    apt-get install openssh-server
    ufw allow ssh
else
    GREEN "SSH Server is already installed"
fi

#Docker
BLUE "Installing Docker..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg --yes    

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install docker-ce docker-ce-cli containerd.io

#Docker Compose
BLUE "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null
then
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
else
    GREEN "Docker Compose is already installed"
fi

#Portainer
BLUE "Installing Portainer..."
if [ ! "$(docker ps -q -f name=portainer)" ]; then
    docker run -d -p 9443:9443 --name portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v $HOME_PATH/Documents/docker-data/portainer/data:/data \
        cr.portainer.io/portainer/portainer-ce:2.9.3
else
    GREEN "Portainer is already installed"
fi

#Creating SSH Config
BLUE "Adding Git SSH Config..."
if !(grep -q "Host github.com" $HOME_PATH/.ssh/config)
then
    echo -e $SSHGIT >> $HOME_PATH/.ssh/config
else
    GREEN "SSH Config for GitHub already exists"
fi

#Creating BMont SSH key
BLUE "Creating SSH Key..."
if !(test -f $HOME_PATH/.ssh/$SSHKEYNAME)
then
    read -p "Insert email for your ssh key: " sshemail
    ssh-keygen -f $HOME_PATH/.ssh/$SSHKEYNAME -t rsa -b 4096 -C $sshemail
else
    GREEN "SSH Key already exists"
fi
sudo chown -R $SUDO_USER: $HOME_PATH/.ssh/

if !(grep -q "export PS1" $HOME_PATH/.bashrc)
then
    BLUE "Forcing a color prompt in ~/.bashrc..."
	echo "export PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> $HOME_PATH/.bashrc
fi

if $FULL_INSTALL
then
#Install Nmap
BLUE "Installing Nmap..."
sudo apt-get install nmap -y

#Install OpenVPN
BLUE "Installing OpenVPN..."
sudo apt-get install openvpn -y

#Install Wireguard
BLUE "Installing Wireguard..."
sudo apt-get install wireguard -y

#Installing Fonts
BLUE "Installing Fonts"
mkdir /usr/share/fonts/Meslo
sudo curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -o "/usr/share/fonts/Meslo/MesloLGS NF Regular.ttf"
sudo curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -o "/usr/share/fonts/Meslo/MesloLGS NF Bold.ttf"
sudo curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -o "/usr/share/fonts/Meslo/MesloLGS NF Italic.ttf"
sudo curl -L https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -o "/usr/share/fonts/Meslo/MesloLGS NF Bold Italic.ttf"
fc-cache /usr/share/fonts/
gsettings set org.gnome.desktop.interface monospace-font-name 'MesloLGS NF 11'

#Install terminator
BLUE "Installing Terminator..."
apt-get install terminator -y
BLUE "Setting terminator as the default terminal emulator..."
sed -i s/Exec=gnome-terminal/Exec=terminator/g /usr/share/applications/org.gnome.Terminal.desktop

#Install zsh
BLUE "Installing Zsh..."
apt-get install zsh -y
usermod -s /usr/bin/zsh $(whoami)

#Install OhMyZsh
BLUE "Installing OhMyZsh..."
sudo -i -u $SUDO_USER bash << EOF
export ZSH=$HOME_PATH/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
EOF

#Installing Powerlevel10k
BLUE "Installing PowerLevel10k"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME_PATH/.oh-my-zsh/custom}/themes/powerlevel10k

#Add custom configuration files
BLUE "Adding Terminator Config..."
rsync -a ./.config/terminator/config $HOME_PATH/.config/terminator/

BLUE "Adding Zsh Config..."
cp -p ./.zshrc $HOME_PATH/.zshrc

BLUE "Adding OhMyZsh..."
cp -rp ./.oh-my-zsh $HOME_PATH/

BLUE "Adding Powerlevel10k..."
cp -p ./.p10k.zsh $HOME_PATH/.p10k.zsh

if [ $(lsb_release -i -s) == "Ubuntu" ]
then
    #Install VS Code
    BLUE "Installing VS Code..."
    sudo snap install --classic code

    #Install Arduino
    BLUE "Installing Arduino..."
    sudo snap install arduino

    #Install GNOME Tweaks
    BLUE "Installing GNOME Tweaks..."
    sudo apt-get install gnome-tweaks -y
fi
fi

#Cleaning
BLUE "Cleaning..."
sudo apt-get autoremove -y
sudo apt-get clean -y

#Success message
BLUE "Finished installation"
