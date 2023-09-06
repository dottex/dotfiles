#Install nvim as a feature
sudo apt update
sudo apt install taskwarrior -y
cp ~/dotfiles/task/.config/task/taskrc_example ~/.taskrc
git clone https://github.com/wakatime/vim-wakatime ~/.local/share/nvim/site/pack/plugins/start/wakatime --depth=1


