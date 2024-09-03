## eBook stack
This stack is purely for management of E-Books. It may break if the Home Services stack is not present.

It consists of the following services:
- Calibre: docker image of the popular eBook management desktop software Calibre. Amongst others, it can convert and email eBooks to your devices
- Calibre-Web: A web frontend for Calibre
- Readarr: Automated ebook management and integration with torrent client

It uses the follow services from the Media stack
- Gluetun: VPN client to provide containers secure outbound connectivity
- Deluge: torrent client. Relies on Gluetun
- Prowlarr: Torrent indexers proxy
- Notifiarr: A notification aggregator

### Data Flow Map
Calibre is the content library, but is not used to edit **any** metadata of the books. It's simply the database tool that:
- stores ebooks
- converts ebooks to different formats

Readarr is the eBook acquisition and management tool, which does all the downloading / managing of the eBook content

Calibre Web is the nicer front end to your library. It allows many different uses to choose to send ebooks to their own devices

**Important notes**
- If you are going to use Calibre integration, then Readarr controls Calibre's database. You cannot add books, delete books, re-tag books, or convert books inside Calibre. All work must be done through Readarr.
- Because Readarr is a tag-based program, it is not recommended to hardlink your torrent downloads. Changing the tags changes the underlying file, which will break your seeds because the file is not the same thing you downloaded. Books are small, turn off hardlinks in Readarr and keep 2 copies.



### Installation notes:
- If you have an existing Calibre library, move it to the `/data/media/books` folder before doing the initial setup of the Calibre container, so that it can be imported on first run.
- - Must do this before adding that library folder to Readarr as a Root Folder (see https://wiki.servarr.com/readarr/quick-start-guide#root-folders-and-calibre-integration)
- configure the Calibre container on port 8080
- enable the Calibre Content server(https://wiki.servarr.com/readarr/quick-start-guide#calibre-content-server-optional)
- configure the [calibre integration in Readarr](https://wiki.servarr.com/readarr/quick-start-guide#calibre-content-server-optional)
- configure Calibre Web. Default creds admin : admin123 (as per https://docs.linuxserver.io/images/docker-calibre-web/#application-setup)



**Download Client**
- add download client in Readarr (TODO: add picture of settings), ensuring you set the [label](https://trash-guides.info/Downloaders/Deluge/Using-Labels/)
- add label in download client, configure it to move files on completed download to `data/torrents/books`



**Indexer**
- get Readarr API key from Settings --> General --> API Key
- Add the Readarr App to Prowlarr, by going to Prowlarr --> Settings --> Apps
- TODO insert image of App addition







TODO:
- insert pictures of settings throughout this page
- configure Readarr quality profiles as per pinned post in Servarr's Readarr discord channel
- steal what I can from https://drive.google.com/file/d/1ppbxG9EbLzqKB-lJiJ0EHygtpAGjZ0SP/view