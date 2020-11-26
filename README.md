# Simple-Bash-Botnet

This is a project to create a simple botnet in bash that can interact with Github Gists.

This is intended as an educational project that's explained in an article in finsin.cl (spanish only https://finsin.cl/2020/11/22/creando-mi-propia-botnet-simple/)

# Installation

Just download the files, the intention here's that you don't need much to run this.

To run the manager you'll need *jq* (https://stedolan.github.io/jq/)

# Setup of the botnet

To make it work, you'll need a Github personal token that can create and manipulate Gists (https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token)

It's recommended to use a new account for this so you don't polute your communication channel with your own gists.

Then you'll need to execute the manager and create the public/private key pair.

Finally copy/paste the complete public key text to the _PUBLIC_ variable on th sbb.sh file. Done!

# Using the botnet

Whenever you want to try the botnet you just need to run the sbb.sh file on the environment you want to use as a bot.

If the execution is successful you'll see a new gist under your account. This is the reporting phase of the bot.

To check all the bots that reported to your account you can use the manager.sh, because it will help you understand right away the code that was uploaded.

After that you'll just need imagination and to keep on playing with your bots:

<img src="manager.png" width="400px">
