#Install nvim as a feature
sudo apt update
sudo apt install taskwarrior -y 
cp ~/dotfiles/task/.config/task/taskrc_example ~/.taskrc #Initial configuration
git clone https://github.com/wakatime/vim-wakatime ~/.local/share/nvim/site/pack/plugins/start/wakatime --depth=1 #shallow history
git clone https://github.com/wakatime/vim-wakatime ~/.vim/pack/plugins/start/wakatime --depth=1 #shallow history
mkdir -p ~/.local/bin && cd ~/.local/bin #Do both or none
curl -LO https://github.com/x-motemen/ghq/releases/download/v1.4.2/ghq_linux_amd64.zip  #Follow redirections and save file
unzip -o ghq_linux_amd64.zip #Overwrite
cp ghq_linux_amd64/ghq .


