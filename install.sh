#Install nvim as a feature
sudo apt update
sudo apt install taskwarrior -y
cp ~/dotfiles/task/.config/task/taskrc_example ~/.taskrc
git clone https://github.com/wakatime/vim-wakatime ~/.local/share/nvim/site/pack/plugins/start/wakatime --depth=1
git clone https://github.com/wakatime/vim-wakatime ~/.vim/pack/plugins/start/wakatime --depth=1
mkdir -p ~/.local/bin && cd ~/.local/bin
curl -L https://github.com/x-motemen/ghq/releases/download/v1.4.2/ghq_linux_amd64.zip -o ghq.zip
unzip ghq.zip
cp ghq/ghq .


