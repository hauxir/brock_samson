# Install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.0
echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
source ~/.bashrc

# Install Erlang plugin
asdf plugin-add erlang

# Install a compatible version of Erlang for Elixir 1.15
asdf install erlang 27.2

# Set the installed Erlang version as the global version
asdf global erlang 27.2

# Install Elixir plugin
asdf plugin-add elixir

# Install Elixir 1.15
asdf install elixir 1.18.0-otp-27

# Set Elixir 1.15 as the global version

asdf global elixir 1.18.0-otp-27

ln -s /root/.asdf/shims/iex /usr/bin/iex
ln -s /root/.asdf/shims/erl /usr/bin/erl
ln -s /root/.asdf/shims/mix /usr/bin/mix

echo "Erlang and Elixir 1.18 installation complete."
