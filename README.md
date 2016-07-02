DokuWiki Docker Container
=========================

Start
-----

	docker run -d -p 8080:80 --name wiki_instance dtwardow/dokuwiki app:start

You can login to the DokuWiki with the superuser account "admin" with the 
password "admin". Please change the password on the first login.

Update Image
-----------

First stop your container

	docker stop wiki_instance

Then run new container just to hold the volumes

	docker run --volumes-from wiki_instance --name wiki_data

Now you can remove old container

	docker rm wiki_instance

..and run a new one (you built, pulled before)

	docker run -d -p 80:80 --name wiki_instance --volumes-from wiki_data dtwardow/dokuwiki app:start

afterwards you can remove data container if you want or keep it for next update

	docker rm wiki_data

Backup and Restore
------------------

Backup to an external TAR-file:

    docker run --rm -it --volumes-from wiki_data -v <path-to-transfer-dir>:/transfer.d dtwardow/dokuwiki app:backup

Restore from external TAR-file:

    docker run --rm -it --volumes-from wiki_data -v <path-to-transfer-dir>:/transfer.d dtwardow/dokuwiki app:restore

Optimizing
----------

Lighttpd configuration also includes rewrites, so you can enable 
nice URLs in settings (Advanced -> Nice URLs, set to ".htaccess")

For better performance enable xsendfile in settings.
Set to proprietary lighttpd header (for lighttpd < 1.5)

Build your own
--------------

	docker build -t own_dokuwiki .

