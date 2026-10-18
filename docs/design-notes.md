# Design notes
## VPN
This is designed to perform Torrent and File acquisition tasks via a VPN. You will need to provide that, or alternatively simply run without one. 

## Hardlinking
This setup uses Hardlinking to minimise unneccessary file I/O. The main idea of it is to have your host folder structure set up as below, and ensure that the containers have these folders [mapped as Volumes in the correct manner](https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/)
```bash
data
├── torrents
│   ├── books
│   ├── movies
│   ├── music
│   └── tv
├── usenet
│   ├── incomplete
│   └── complete
│       ├── books
│       ├── movies
│       ├── music
│       └── tv
└── media
    ├── books
    ├── movies
    ├── music
    └── tv
```
See [TRaSH Guides](https://trash-guides.info/Hardlinks/Hardlinks-and-Instant-Moves/) for more info.


## Updating
Watchtower is included in order to keep containers updated. If you choose not to deploy this, the containers deployed simply won’t get automatic updates via the Watchtower mechanism. You are welcome to choose another automated update mechanism, or update the containers manually.

## User security
- Most of the containers are set up to run on the host system under their own user. This is a security-based decision, aimed at reducing the impact of any single user of the host system being compromised. If you don’t want to deal with all the users, simply run these containers as the one user, things wil still work.
- Some of the containers have to run as a privileged user; often `root`. They are called out as such, as is the reasoning. If you find a way to circumvent that need, please let me know!
- For more on this, see Docker’s [blog post](https://www.docker.com/blog/understanding-the-docker-user-instruction/) about the `USER` directive, as well as how LinuxServer.io’s docker images facilitate [setting the user that a container runs as](https://docs.linuxserver.io/general/understanding-puid-and-pgid/)

## Discord Notifications
To keep track of what’s going on with the whole setup, Notifiarr will send messages to a Discord server of your configuration. This requires you to set up a Discord server (free), and run a Notifiarr container linked to a Notifiarr account.
It can be configured as you desire, eg. give updates on new or deleted media content, updated containers, when a Plex stream starts / stops (useful if your media library is shared amongst multiple users)

## Media Quality
The quality of the media you download (720p, 1080p, 2160p etc.) depends on the Quality Profiles (QPs) you configure. This is a [deep rabbit hole to go down](https://trash-guides.info/Radarr/radarr-setup-quality-profiles/), and I’ve chosen to use TRaSH Guides’ regularly updated QPs instead of trying to maintain my own.

I’ve also chosen to buy a $10 AUD license for Notifiarr, which automates the job of keeping my QPs in sync. I am aware this could be done with [Recyclarr](https://trash-guides.info/Recyclarr/) for free, however I am already using Notifiarr for many other things and figured $10 is the least I can do to support the devs.

You do not need to do this. You can simply 

## RSS Downloads
Certain things don’t support proper episode downloading - namely sports. I like F1 (and absolutely hate Kayo / Foxtel), and using RSS feeds allows me to automate *most* of the work of acquiring the content. For more details, read [RSS Downloads.md](RSS_Downloads.md)