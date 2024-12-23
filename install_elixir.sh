# Install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.0
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
source ~/.bashrc

bash /install_erlang.sh
# Install Erlang plugin
#asdf plugin-add erlang

# Install a compatible version of Erlang for Elixir 1.15
#asdf install erlang 27.0.1

# Set the installed Erlang version as the global version
#asdf global erlang 27.0.1

# Install Elixir plugin
asdf plugin-add elixir

# Install Elixir 1.15
asdf install elixir 1.17.2-otp-27

# Set Elixir 1.15 as the global version

asdf global elixir 1.17.2-otp-27

ln -s /root/.asdf/shims/iex /usr/bin/iex
ln -s /root/.asdf/shims/erl /usr/bin/erl
ln -s /root/.asdf/shims/mix /usr/bin/mix

echo "Erlang and Elixir 1.17 installation complete."
