# Jobmon
*An email notifier for the University of Waterloo's JobMine service.*

by Peter Sobot (psobot.com) on September 27, 2012. Licensed under MIT.

---

Jobmon is a simple, email-based JobMine interview monitor. Edit the config file, add your user credentials, and find out instantly (kinda) when anything changes in your JobMine applications.

Requires a (free!) API key from [PostageApp](http://postageapp.com/) to send emails reliably.

---

##Installation

    git clone https://github.com/psobot/jobmon.git
    cd jobmon
    bundle install
    vim config.example.rb
    mv config.example.rb config.rb

To daemonize and run forever:

    ruby jobmon.rb start

To stop a running jobmon process:

    ruby jobmon.rb stop
