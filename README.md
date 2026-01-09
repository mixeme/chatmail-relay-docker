# chatmail-relay-docker
Dockerfile and docker-compose for chatmail relay deployment

## How it works
The idea is to take Debian 12 docker image, setup systemd and sshd without root password. Run container with this docker image and run chatmail deploy commands with flag `--ssh-host localhost` inside container.

## How to deploy
### Pre Requirements

1. Open chatmail relay setup [documentation](https://chatmail.at/doc/relay/getting_started.html#setting-up-a-chatmail-relay) and read it


2. You need setup your local http server first or if you don't have local http server change exposed container ports 80 and 443 in docker-compose.yml

2.1. Expose 80 and 443

Current

```
ports:
  - "8080:80"
  - "9443:443"
```

Change to

```
ports:
  - "80:80"
  - "443:443"
```

Port `80` is needed to be able to get certificates with acmetool inside container

Port `443` Multiplex HTTPS, IMAP and SMTP


2.2. Setup local http server (nginx as an example)

2.2.1 Create config `your-chat-domain.com` in `/etc/nginx/sites-enabled`

Example:

```
server {
  listen 80;
  listen [::]:80;
  server_name your-chat-domain.com www.your-chat-domain.com mta-sts.your-chat-domain.com;
  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_pass http://127.0.0.1:8080;
  }
}
```

And if you have https (443) sites on your local nginx server, you should setup tls-pass-passthrough, because chatmail serves `443` by itself and you shouldn't terminate TLS connection on nginx level.

You should change all `443` ports in your nginx configs to `8443`

Create file `/etc/nginx/passthrough.conf`

```
stream {
    # Define upstreams for different domains
    upstream local_tls {
        server 127.0.0.1:8443; # your local https domains
    }

    upstream chatmail_tls {
        server 127.0.0.1:9443; # your chatmail docker setup
    }
    # SNI-based routing for TLS passthrough
    map $ssl_preread_server_name $upstream {
        your-chat-domain.com    chatmail_tls;
        mta-sts.your-chat-domain.com    chatmail_tls;
        www.your-chat-domain.com    chatmail_tls;
        default             local_tls;

    }
    server {
        listen 443;
        listen [::]:443;

        ssl_preread on;
        proxy_pass $upstream;
    }
}
```

Include `/etc/nginx/passthrough.conf` in your `/etc/nginx/nginx.conf`

```
{
....
        ##
        # Virtual Host Configs
        ##

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}

# insert this line
include /etc/nginx/passthrough.conf;

#mail {
...
}
```

### Deploy docker container

1. `docker compose up -d --build`
2. `docker compose exec chatmail bash`
3. `./scripts/cmdeploy init your-chat-domain.com`
4. `vim chatmail.ini` and edit settings if needed
5. `./scripts/cmdeploy run --ssh-host localhost`
6. `./scripts/cmdeploy dns --ssh-host localhost` and set all required and recomended DNS records
7. Repeat `./scripts/cmdeploy dns --ssh-host localhost` until you get success message
8. Check that all ports are LISTENED `apt install net-tools && netstat -an | grep LISTEN`. You should see this ports `25 80 143 443 465 587 993`. I had missing 25/587/465 because postfix hadn't started. In that case exit container and restart it `docker compose stop && docker compose start`. Attach to container again `docker compose exec chatmail bash` and check ports again
9. You can run tests with command `./scripts/cmdeploy test`. Not all tests will pass. Tests which connect via ssh to server to check deployment will fail because test command doesn't have `--ssh-host flag`

That's it. You probably have a working chatmail relay. (Don't forget to open ports on your server)