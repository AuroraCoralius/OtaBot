# Dream Bot Mark II
**[Discord](https://discordapp.com)** Bot written in Lua, using the **[Discordia](https://github.com/SinisterRectus/Discordia)** API library and **[Luvit](https://luvit.io/)** runtime environment.

### Installation
- To install Luvit, visit https://luvit.io and follow the instructions provided for your platform.
- To install Discordia, run `lit install SinisterRectus/discordia`.
- Clone this repository.
- Rename `config_example.lua` to `config.lua` and change it to your liking.
  - Go to the **[Discord Applications](https://discordapp.com/developers/applications/me)** page and create an application in it
  - Give the application a bot user, and put its token in the `token` field of the config.
  - Invite your bot to your server using this URL: <https://discordapp.com/oauth2/authorize?client_id=CLIENT_ID&scope=bot&permissions=0>
    - Replace `CLIENT_ID` by the Client ID displayed on your application's page.
  - To set yourself as owner, turn on the developer mode in Discord's options and get your user ID **[like so](https://i.imgur.com/41DcCCG.png)**. Then you can add it to the config file the same way as I added mine.
- Run the bot inside of the repository's folder using `luvit bot.lua`.
- Some features may only work if you supply valid credentials / API keys related to them and give the bot enough permissions. (example: color roles related commands require role management permissions) 

### Usage
Type `$help` in a channel your bot has access to or in a private message and the bot will print out all of the available commands.

Command parsing goes like this: `$test "hello 1 2 3",yes`.

The arguments supplied to a command would be `hello 1 2 3` and `yes`.
